class Subscription < ActiveRecord::Base
  include NotifyWith::NotificationAttachedObject

  belongs_to :plan
  belongs_to :user

  has_many :invoices, as: :invoiced, dependent: :destroy
  has_many :offer_days, dependent: :destroy

  validates_presence_of :plan_id
  validates_with SubscriptionGroupValidator

  attr_accessor :card_token

  # creation
  after_save :notify_member_subscribed_plan, if: :is_new?
  after_save :notify_admin_subscribed_plan, if: :is_new?
  after_save :notify_partner_subscribed_plan, if: :of_partner_plan?

  # Stripe subscription payment
  # @params [invoice] if true then subscription pay itself, dont pay with reservation
  #                   if false then subscription pay with reservation
  def save_with_payment(invoice = true, coupon_code = nil)
    if valid?
      begin
        customer = Stripe::Customer.retrieve(user.stp_customer_id)
        invoice_items = []

        unless coupon_code.nil?
          @coupon = Coupon.find_by(code: coupon_code)
          if not @coupon.nil? and @coupon.status(user.id) == 'active'
            total = plan.amount

            discount = 0
            if @coupon.type == 'percent_off'
              discount = (total  * @coupon.percent_off / 100).to_i
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
          else
            raise InvalidCouponError
          end
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
        # very important to set expired_at to nil that can allow method is_new? to return true
        # for send the notification
        # TODO: Refactoring
        update_column(:expired_at, nil) unless new_record?
        self.stp_subscription_id = new_subscription.id
        self.canceled_at = nil
        self.expired_at = Time.at(new_subscription.current_period_end)
        save!

        UsersCredits::Manager.new(user: self.user).reset_credits if expired_date_changed

        # generate invoice
        stp_invoice = Stripe::Invoice.all(customer: user.stp_customer_id, limit: 1).data.first
        if invoice
          invoc = generate_invoice(stp_invoice.id, coupon_code)
          # debit wallet
          wallet_transaction = debit_user_wallet
          if wallet_transaction
            invoc.wallet_amount = @wallet_amount_debit
            invoc.wallet_transaction_id = wallet_transaction.id
          end
          invoc.save
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
      rescue => e
        clear_wallet_and_goupon_invoice_items(invoice_items)
        # Something else happened, completely unrelated to Stripe
        logger.error e
        errors[:payment] << e.message
        return false
      end
    end
  end

  # @params [invoice] if true then subscription pay itself, dont pay with reservation
  #                   if false then subscription pay with reservation
  def save_with_local_payment(invoice = true, coupon_code = nil)
    if valid?
      # very important to set expired_at to nil that can allow method is_new? to return true
      # for send the notification
      # TODO: Refactoring
      update_column(:expired_at, nil) unless new_record?
      self.stp_subscription_id = nil
      self.canceled_at = nil
      set_expired_at
      if save
        UsersCredits::Manager.new(user: self.user).reset_credits if expired_date_changed
        if invoice
          @wallet_amount_debit = get_wallet_amount_debit

          # debit wallet
          wallet_transaction = debit_user_wallet

          if !self.user.invoicing_disabled?
            invoc = generate_invoice(nil, coupon_code)
            if wallet_transaction
              invoc.wallet_amount = @wallet_amount_debit
              invoc.wallet_transaction_id = wallet_transaction.id
            end
            invoc.save
          end
        end
        return true
      else
        return false
      end
    else
      return false
    end
  end

  def generate_invoice(stp_invoice_id = nil, coupon_code = nil)
    coupon_id = nil
    total = plan.amount

    unless coupon_code.nil?
      @coupon = Coupon.find_by(code: coupon_code)

      unless @coupon.nil?
        total = CouponService.new.apply(plan.amount, @coupon, user.id)
        coupon_id = @coupon.id
      end
    end

    invoice = Invoice.new(invoiced_id: id, invoiced_type: 'Subscription', user: user, total: total, stp_invoice_id: stp_invoice_id, coupon_id: coupon_id)
    invoice.invoice_items.push InvoiceItem.new(amount: plan.amount, stp_invoice_item_id: stp_subscription_id, description: plan.name, subscription_id: self.id)
    invoice
  end

  def generate_and_save_invoice(stp_invoice_id = nil)
    generate_invoice(stp_invoice_id).save
  end

  def generate_and_save_offer_day_invoice(offer_day_start_at)
    od = offer_days.create(start_at: offer_day_start_at, end_at: expired_at)
    invoice = Invoice.new(invoiced_id: od.id, invoiced_type: 'OfferDay', user: user, total: 0)
    invoice.invoice_items.push InvoiceItem.new(amount: 0, description: plan.name, subscription_id: self.id)
    invoice.save
  end

  def cancel
    if stp_subscription_id.present?
      stp_subscription = stripe_subscription
      stp_subscription.delete(at_period_end: true)
      update_columns(canceled_at: Time.now)
    end
  end

  def stripe_subscription
    user.stripe_customer.subscriptions.retrieve(stp_subscription_id) if stp_subscription_id.present?
  end

  def expire(time)
    if !is_expired?
      update_columns(expired_at: time, canceled_at: time)
      notify_admin_subscription_canceled
      notify_member_subscription_canceled
      true
    else
      false
    end
  end

  def is_expired?
    expired_at <= Time.now
  end

  def extend_expired_date(expired_at, free_days = false)
    return false if expired_at <= self.expired_at

    self.expired_at = expired_at
    if save
      UsersCredits::Manager.new(user: self.user).reset_credits if !free_days
      notify_subscription_extended(free_days)
      return true
    end
    return false
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
    meta_data[:free_days] = true if free_days == true
    notification = Notification.new(meta_data: meta_data)
    notification.send_notification(type: :notify_member_subscription_extended, attached_object: self).to(user).deliver_later

    User.admins.each do |admin|
      notification = Notification.new(meta_data: meta_data)
      notification.send_notification(type: :notify_admin_subscription_extended, attached_object: self).to(admin).deliver_later
    end
  end

  # set a expired date by plan
  # expired_at will be updated when has a new payment
  def set_expired_at
    start_at = Time.now
    self.expired_at = start_at + plan.duration
  end

  def expired_date_changed
    p_value = self.previous_changes[:expired_at][0]
    return true if p_value.nil?
    p_value.to_date != expired_at.to_date and expired_at > p_value
  end

  # def is_being_extended?
  #   !expired_at_was.nil? and expired_at_changed?
  # end

  def is_new?
    expired_at_was.nil?
  end

  def of_partner_plan?
    plan.is_a?(PartnerPlan)
  end

  def get_wallet_amount_debit
    total = plan.amount
    if @coupon
      total = CouponService.new.apply(total, @coupon, user.id)
    end
    wallet_amount = (user.wallet.amount * 100).to_i
    return wallet_amount >= total ? total : wallet_amount
  end

  def debit_user_wallet
    if @wallet_amount_debit.present? and @wallet_amount_debit != 0
      amount = @wallet_amount_debit / 100.0
      return WalletService.new(user: user, wallet: user.wallet).debit(amount, self)
    end
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
