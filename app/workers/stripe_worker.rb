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
    Stripe::Coupon.create(
        id: coupon.code,
        duration: coupon.validity_per_user,
        percent_off: coupon.percent_off,
        redeem_by: coupon.valid_until.to_i,
        max_redemptions: coupon.max_usages,
    )
  end

  def delete_stripe_coupon(coupon_code)
    cpn = Stripe::Coupon.retrieve(coupon_code)
    cpn.delete
  end
end
