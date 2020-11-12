# frozen_string_literal: true

# This worker perform various requests to the Stripe API (payment service)
class StripeWorker
  include Sidekiq::Worker
  sidekiq_options queue: :stripe

  def perform(action, *params)
    send(action, *params)
  end

  def create_stripe_customer(user_id)
    user = User.find(user_id)
    customer = Stripe::Customer.create(
      {
        description: user.profile.full_name,
        email: user.email
      },
      { api_key: Setting.get('stripe_secret_key') }
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

    Stripe::Coupon.create(stp_coupon, api_key: Setting.get('stripe_secret_key'))
  end

  def delete_stripe_coupon(coupon_code)
    cpn = Stripe::Coupon.retrieve(coupon_code, api_key: Setting.get('stripe_secret_key'))
    cpn.delete
  end

  def create_or_update_stp_product(class_name, id)
    object = class_name.constantize.find(id)
    if !object.stp_product_id.nil?
      Stripe::Product.update(
        object.stp_product_id,
        { name: object.name },
        { api_key: Setting.get('stripe_secret_key') }
      )
      p.product
    else
      product = Stripe::Product.create(
        {
          name: object.name,
          metadata: {
            id: object.id,
            type: class_name
          }
        }, { api_key: Setting.get('stripe_secret_key') }
      )
      object.update_attributes(stp_product_id: product.id)
    end
  end

  def create_stripe_subscription(payment_schedule_id, first_invoice_items)
    payment_schedule = PaymentSchedule.find(payment_schedule_id)

    items = []
    first_invoice_items.each do |fii|
      # TODO, fill this prices with real data
      price = Stripe::Price.create({
                                     unit_amount: 2000,
                                     currency: 'eur',
                                     recurring: { interval: 'month' },
                                     product_data: {
                                       name: 'lorem ipsum'
                                     }
                                   },
                                   { api_key: Setting.get('stripe_secret_key') })
      items.push(price: price[:id])
    end
    stp_subscription = Stripe::Subscription.create({
                                                     customer: payment_schedule.invoicing_profile.user.stp_customer_id,
                                                     cancel_at: payment_schedule.scheduled.expiration_date,
                                                     promotion_code: payment_schedule.coupon&.code,
                                                     add_invoice_items: items,
                                                     items: [
                                                       { price: payment_schedule.scheduled.plan.stp_price_id }
                                                     ]
                                                   }, { api_key: Setting.get('stripe_secret_key') })
    payment_schedule.update_attributes(stp_subscription_id: stp_subscription.id)
  end
end
