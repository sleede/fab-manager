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
  def save_with_payment(invoice = true)
    if valid?
      customer = Stripe::Customer.retrieve(user.stp_customer_id)
      begin
        # dont add a wallet invoice item if pay subscription by reservation
        if invoice
          @wallet_amount_debit = get_wallet_amount_debit
          if @wallet_amount_debit != 0
            Stripe::InvoiceItem.create(
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
        self.expired_at = Time.at(new_subscription.current_period_end)
        save!

        UsersCredits::Manager.new(user: self.user).reset_credits if expired_date_changed

        # generate invoice
        stp_invoice = Stripe::Invoice.all(customer: user.stp_customer_id, limit: 1).data.first
        if invoice
          invoc = generate_invoice(stp_invoice.id)
          # debit wallet
          invoc.wallet_amount = @wallet_amount_debit if debit_user_wallet
          invoc.save
        end
        # cancel subscription after create
        cancel
        return true
      rescue Stripe::CardError => card_error
        logger.error card_error
        errors[:card] << card_error.message
        return false
      rescue Stripe::InvalidRequestError => e
        # Invalid parameters were supplied to Stripe's API
        logger.error e
        errors[:payment] << e.message
        return false
      rescue Stripe::AuthenticationError => e
        # Authentication with Stripe's API failed
        # (maybe you changed API keys recently)
        logger.error e
        errors[:payment] << e.message
        return false
      rescue Stripe::APIConnectionError => e
        # Network communication with Stripe failed
        logger.error e
        errors[:payment] << e.message
        return false
      rescue Stripe::StripeError => e
        # Display a very generic error to the user, and maybe send
        # yourself an email
        logger.error e
        errors[:payment] << e.message
        return false
      rescue => e
        # Something else happened, completely unrelated to Stripe
        logger.error e
        errors[:payment] << e.message
        return false
      end
    end
  end

  def save_with_local_payment(invoice = true)
    if valid?
      @wallet_amount_debit = get_wallet_amount_debit if invoice

      self.stp_subscription_id = nil
      self.canceled_at = nil
      set_expired_at
      save!
      UsersCredits::Manager.new(user: self.user).reset_credits if expired_date_changed
      if invoice
        invoc = generate_invoice
        # debit wallet
        invoc.wallet_amount = @wallet_amount_debit if debit_user_wallet
        invoc.save
      end
      return true
    else
      return false
    end
  end

  def generate_invoice(stp_invoice_id = nil)
    invoice = Invoice.new(invoiced_id: id, invoiced_type: 'Subscription', user: user, total: plan.amount, stp_invoice_id: stp_invoice_id)
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
    wallet_amount = (user.wallet.amount * 100).to_i
    return wallet_amount >= total ? total : wallet_amount
  end

  def debit_user_wallet
    if @wallet_amount_debit.present? and @wallet_amount_debit != 0
      amount = @wallet_amount_debit / 100.0
      WalletService.new(user: user, wallet: user.wallet).debit(amount, self)
    end
  end
end
