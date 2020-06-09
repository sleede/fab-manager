# frozen_string_literal: true

# This worker perform various requests to the Stripe API (payment service)
class StripeWorker
  include Sidekiq::Worker
  sidekiq_options queue: :stripe

  LOGGER = Sidekiq.logger.level == Logger::DEBUG ? Sidekiq.logger : nil

  def perform(action, *params)
    send(action, *params)
  end

  def create_stripe_customer(user_id)
    user = User.find(user_id)
    customer = Stripe::Customer.create(
      description: user.profile.full_name,
      email: user.email
    )
    user.update_columns(stp_customer_id: customer.id)
  end

  def create_stripe_coupon(coupon_id)
    coupon = Coupon.find(coupon_id)
    stp_coupon = {
      id: coupon.code,
      duration: coupon.validity_per_user
    }
    if coupon.type == 'percent_off'
      stp_coupon[:percent_off] = coupon.percent_off
    elsif coupon.type == 'amount_off'
      stp_coupon[:amount_off] = coupon.amount_off
      stp_coupon[:currency] = Rails.application.secrets.stripe_currency
    end

    stp_coupon[:redeem_by] = coupon.valid_until.to_i unless coupon.valid_until.nil?
    stp_coupon[:max_redemptions] = coupon.max_usages unless coupon.max_usages.nil?

    Stripe::Coupon.create(stp_coupon)
  end

  def delete_stripe_coupon(coupon_code)
    cpn = Stripe::Coupon.retrieve(coupon_code)
    cpn.delete
  end

  def sync_members
    LOGGER&.debug ['StripeWorker', 'SyncMembers', 'We create all non-existing customers on stripe. This may take a while...']
    total = User.online_payers.count
    User.online_payers.each_with_index do |member, index|
      LOGGER&.debug ['StripeWorker', 'SyncMembers' "#{index} / #{total}"]
      begin
        stp_customer = Stripe::Customer.retrieve member.stp_customer_id
        create_stripe_customer(member.id) if stp_customer.nil? || stp_customer[:deleted]
      rescue Stripe::InvalidRequestError
        create_stripe_customer(member.id)
      end
    end
    LOGGER&.debug ['StripeWorker', 'SyncMembers', 'Sync is done']
    notify_user = Setting.find_by(name: 'stripe_secret_key')&.history_values&.last&.invoicing_profile&.user
    return unless notify_user

    NotificationCenter.call type: :notify_admin_members_stripe_sync,
                            receiver: notify_user
  end
end
