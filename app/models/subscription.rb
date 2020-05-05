# frozen_string_literal: true

# Subscription is an active or archived subscription of an User to a Plan
class Subscription < ApplicationRecord
  include NotifyWith::NotificationAttachedObject

  belongs_to :plan
  belongs_to :statistic_profile

  has_many :invoices, as: :invoiced, dependent: :destroy
  has_many :offer_days, dependent: :destroy

  validates_presence_of :plan_id
  validates_with SubscriptionGroupValidator

  # creation
  after_save :notify_member_subscribed_plan
  after_save :notify_admin_subscribed_plan
  after_save :notify_partner_subscribed_plan, if: :of_partner_plan?

  # @param invoice if true then only the subscription is payed, without reservation
  #                if false then the subscription is payed with reservation
  def save_with_payment(operator_profile_id, invoice = true, coupon_code = nil, payment_intent_id = nil)
    return false unless valid?

    set_expiration_date
    return false unless save

    UsersCredits::Manager.new(user: user).reset_credits
    if invoice
      @wallet_amount_debit = get_wallet_amount_debit

      # debit wallet
      wallet_transaction = debit_user_wallet

      invoc = generate_invoice(operator_profile_id, coupon_code, payment_intent_id)
      if wallet_transaction
        invoc.wallet_amount = @wallet_amount_debit
        invoc.wallet_transaction_id = wallet_transaction.id
      end
      invoc.save
    end
    true
  end

  def generate_invoice(operator_profile_id, coupon_code = nil, payment_intent_id = nil)
    coupon_id = nil
    total = plan.amount
    operator = InvoicingProfile.find(operator_profile_id)&.user
    method = operator&.admin? || (operator&.manager? && operator != user) ? nil : 'stripe'

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
      coupon_id: coupon_id,
      operator_profile_id: operator_profile_id,
      stp_payment_intent_id: payment_intent_id,
      payment_method: method
    )
    invoice.invoice_items.push InvoiceItem.new(
      amount: plan.amount,
      description: plan.name,
      subscription_id: id
    )
    invoice
  end

  def generate_and_save_invoice(operator_profile_id)
    generate_invoice(operator_profile_id).save
  end

  def cancel
    update_columns(canceled_at: DateTime.current)
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
    expired_at <= DateTime.current
  end

  def expired_at
    last_offered = offer_days.order(:end_at).last
    return last_offered.end_at if last_offered

    expiration_date
  end

  def free_extend(expiration, operator_profile_id)
    return false if expiration <= expired_at

    od = offer_days.create(start_at: expired_at, end_at: expiration)
    invoice = Invoice.new(
      invoiced_id: od.id,
      invoiced_type: 'OfferDay',
      invoicing_profile: user.invoicing_profile,
      statistic_profile: user.statistic_profile,
      operator_profile_id: operator_profile_id,
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
                            receiver: User.admins_and_managers,
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
                            receiver: User.admins_and_managers,
                            attached_object: self,
                            meta_data: meta_data
  end

  def set_expiration_date
    start_at = DateTime.current.in_time_zone
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
    return if !@wallet_amount_debit.present? || @wallet_amount_debit.zero?

    amount = @wallet_amount_debit / 100.0
    WalletService.new(user: user, wallet: user.wallet).debit(amount, self)
  end
end
