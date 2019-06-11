class Subscription < ActiveRecord::Base
  include NotifyWith::NotificationAttachedObject

  belongs_to :plan
  belongs_to :statistic_profile

  has_many :invoices, as: :invoiced, dependent: :destroy
  has_many :offer_days, dependent: :destroy

  validates_presence_of :plan_id
  validates_with SubscriptionGroupValidator

  attr_accessor :card_token

  # creation
  after_save :notify_member_subscribed_plan
  after_save :notify_admin_subscribed_plan
  after_save :notify_partner_subscribed_plan, if: :of_partner_plan?

  # Stripe subscription payment
  # @param invoice if true then subscription pay itself, dont pay with reservation
  #                if false then subscription pay with reservation
  def save_with_payment(operator_id, invoice = true, coupon_code = nil)
    return unless valid?

    begin
      customer = Stripe::Customer.retrieve(user.stp_customer_id)
      invoice_items = []

      unless coupon_code.nil?
        @coupon = Coupon.find_by(code: coupon_code)
        raise InvalidCouponError if @coupon.nil? || @coupon.status(user.id) != 'active'

        total = plan.amount

        discount = 0
        if @coupon.type == 'percent_off'
          discount = (total * @coupon.percent_off / 100).to_i
        elsif @coupon.type == 'amount_off'
          discount = @coupon.amount_off
        else
          raise InvalidCouponError
        end

        invoice_items << Stripe::InvoiceItem.create(
          customer: user.stp_customer_id,
          amount: -discount,
          currency: Rails.application.secrets.stripe_currency,
          description: "coupon #{@coupon.code} - subscription"
        )
      end

      # only add a wallet invoice item if pay subscription
      # dont add if pay subscription + reservation
      if invoice
        @wallet_amount_debit = get_wallet_amount_debit
        if @wallet_amount_debit != 0
          invoice_items << Stripe::InvoiceItem.create(
            customer: user.stp_customer_id,
            amount: -@wallet_amount_debit,
            currency: Rails.application.secrets.stripe_currency,
            description: "wallet -#{@wallet_amount_debit / 100.0}"
          )
        end
      end

      new_subscription = customer.subscriptions.create(plan: plan.stp_plan_id, source: card_token)
      self.stp_subscription_id = new_subscription.id
      self.canceled_at = nil
      self.expiration_date = Time.at(new_subscription.current_period_end)
      save!

      UsersCredits::Manager.new(user: user).reset_credits

      # generate invoice
      stp_invoice = Stripe::Invoice.all(customer: user.stp_customer_id, limit: 1).data.first
      if invoice
        db_invoice = generate_invoice(operator_id, stp_invoice.id, coupon_code)
        # debit wallet
        wallet_transaction = debit_user_wallet
        if wallet_transaction
          db_invoice.wallet_amount = @wallet_amount_debit
          db_invoice.wallet_transaction_id = wallet_transaction.id
        end
        db_invoice.save
      end
      # cancel subscription after create
      cancel
      return true
    rescue Stripe::CardError => card_error
      clear_wallet_and_goupon_invoice_items(invoice_items)
      logger.error card_error
      errors[:card] << card_error.message
      return false
    rescue Stripe::InvalidRequestError => e
      clear_wallet_and_goupon_invoice_items(invoice_items)
      # Invalid parameters were supplied to Stripe's API
      logger.error e
      errors[:payment] << e.message
      return false
    rescue Stripe::AuthenticationError => e
      clear_wallet_and_goupon_invoice_items(invoice_items)
      # Authentication with Stripe's API failed
      # (maybe you changed API keys recently)
      logger.error e
      errors[:payment] << e.message
      return false
    rescue Stripe::APIConnectionError => e
      clear_wallet_and_goupon_invoice_items(invoice_items)
      # Network communication with Stripe failed
      logger.error e
      errors[:payment] << e.message
      return false
    rescue Stripe::StripeError => e
      clear_wallet_and_goupon_invoice_items(invoice_items)
      # Display a very generic error to the user, and maybe send
      # yourself an email
      logger.error e
      errors[:payment] << e.message
      return false
    rescue StandardError => e
      clear_wallet_and_goupon_invoice_items(invoice_items)
      # Something else happened, completely unrelated to Stripe
      logger.error e
      errors[:payment] << e.message
      return false
    end
  end

  # @param invoice if true then only the subscription is payed, without reservation
  #                if false then the subscription is payed with reservation
  def save_with_local_payment(operator_id, invoice = true, coupon_code = nil)
    return false unless valid?

    set_expiration_date
    return false unless save

    UsersCredits::Manager.new(user: user).reset_credits
    if invoice
      @wallet_amount_debit = get_wallet_amount_debit

      # debit wallet
      wallet_transaction = debit_user_wallet

      invoc = generate_invoice(operator_id, nil, coupon_code)
      if wallet_transaction
        invoc.wallet_amount = @wallet_amount_debit
        invoc.wallet_transaction_id = wallet_transaction.id
      end
      invoc.save
    end
    true
  end

  def generate_invoice(operator_id, stp_invoice_id = nil, coupon_code = nil)
    coupon_id = nil
    total = plan.amount

    unless coupon_code.nil?
      @coupon = Coupon.find_by(code: coupon_code)

      unless @coupon.nil?
        total = CouponService.new.apply(plan.amount, @coupon, user.id)
        coupon_id = @coupon.id
      end
    end

    invoice = Invoice.new(
      invoiced_id: id,
      invoiced_type: 'Subscription',
      invoicing_profile: user.invoicing_profile,
      statistic_profile: user.statistic_profile,
      total: total,
      stp_invoice_id: stp_invoice_id,
      coupon_id: coupon_id,
      operator_id: operator_id
    )
    invoice.invoice_items.push InvoiceItem.new(
      amount: plan.amount,
      stp_invoice_item_id: stp_subscription_id,
      description: plan.name,
      subscription_id: id
    )
    invoice
  end

  def generate_and_save_invoice(operator_id, stp_invoice_id = nil)
    generate_invoice(operator_id, stp_invoice_id).save
  end

  def cancel
    return unless stp_subscription_id.present?

    stp_subscription = stripe_subscription
    stp_subscription.delete(at_period_end: true)
    update_columns(canceled_at: Time.now)
  end

  def stripe_subscription
    user.stripe_customer.subscriptions.retrieve(stp_subscription_id) if stp_subscription_id.present?
  end

  def expire(time)
    if !expired?
      update_columns(expiration_date: time, canceled_at: time)
      notify_admin_subscription_canceled
      notify_member_subscription_canceled
      true
    else
      false
    end
  end

  def expired?
    expired_at <= Time.now
  end

  def expired_at
    last_offered = offer_days.order(:end_at).last
    return last_offered.end_at if last_offered

    expiration_date
  end

  def free_extend(expiration, operator_id)
    return false if expiration <= expired_at

    od = offer_days.create(start_at: expired_at, end_at: expiration)
    invoice = Invoice.new(
      invoiced_id: od.id,
      invoiced_type: 'OfferDay',
      invoicing_profile: user.invoicing_profile,
      statistic_profile: user.statistic_profile,
      operator_id: operator_id,
      total: 0
    )
    invoice.invoice_items.push InvoiceItem.new(amount: 0, description: plan.name, subscription_id: id)
    invoice.save

    if save
      notify_subscription_extended(true)
      return true
    end
    false
  end

  def user
    statistic_profile.user
  end

  private

  def notify_member_subscribed_plan
    NotificationCenter.call type: 'notify_member_subscribed_plan',
                            receiver: user,
                            attached_object: self
  end

  def notify_admin_subscribed_plan
    NotificationCenter.call type: 'notify_admin_subscribed_plan',
                            receiver: User.admins,
                            attached_object: self
  end

  def notify_admin_subscription_canceled
    NotificationCenter.call type: 'notify_admin_subscription_canceled',
                            receiver: User.admins,
                            attached_object: self
  end

  def notify_member_subscription_canceled
    NotificationCenter.call type: 'notify_member_subscription_canceled',
                            receiver: user,
                            attached_object: self
  end

  def notify_partner_subscribed_plan
    NotificationCenter.call type: 'notify_partner_subscribed_plan',
                            receiver: plan.partners,
                            attached_object: self
  end

  def notify_subscription_extended(free_days)
    meta_data = {}
    meta_data[:free_days] = true if free_days
    NotificationCenter.call type: :notify_member_subscription_extended,
                            receiver: user,
                            attached_object: self,
                            meta_data: meta_data

    NotificationCenter.call type: :notify_admin_subscription_extended,
                            receiver: User.admins,
                            attached_object: self,
                            meta_data: meta_data
  end

  def set_expiration_date
    start_at = Time.now
    self.expiration_date = start_at + plan.duration
  end

  def of_partner_plan?
    plan.is_a?(PartnerPlan)
  end

  def get_wallet_amount_debit
    total = plan.amount
    total = CouponService.new.apply(total, @coupon, user.id) if @coupon
    wallet_amount = (user.wallet.amount * 100).to_i
    wallet_amount >= total ? total : wallet_amount
  end

  def debit_user_wallet
    return unless @wallet_amount_debit.present? || @wallet_amount_debit.zero?

    amount = @wallet_amount_debit / 100.0
    WalletService.new(user: user, wallet: user.wallet).debit(amount, self)
  end

  def clear_wallet_and_goupon_invoice_items(invoice_items)
    begin
      invoice_items.each(&:delete)
    rescue Stripe::InvalidRequestError => e
      logger.error e
    rescue Stripe::AuthenticationError => e
      logger.error e
    rescue Stripe::APIConnectionError => e
      logger.error e
    rescue Stripe::StripeError => e
      logger.error e
    rescue => e
      logger.error e
    end
  end
end
