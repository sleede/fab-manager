class StripeWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :stripe

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
        duration: coupon.validity_per_user,
    }
    if coupon.type == 'percent_off'
      stp_coupon[:percent_off] = coupon.percent_off
    elsif coupon.type == 'amount_off'
      stp_coupon[:amount_off] = coupon.amount_off
      stp_coupon[:currency] = Rails.application.secrets.stripe_currency
    end

    unless coupon.valid_until.nil?
      stp_coupon[:redeem_by] = coupon.valid_until.to_i
    end
      stp_coupon
    unless coupon.max_usages.nil?
      stp_coupon[:max_redemptions] = coupon.max_usages
    end

    Stripe::Coupon.create(stp_coupon)
  end

  def delete_stripe_coupon(coupon_code)
    cpn = Stripe::Coupon.retrieve(coupon_code)
    cpn.delete
  end
end
