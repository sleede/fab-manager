# frozen_string_literal: true

# Helpers and utilities for interactions with the Stripe payment gateway
class StripeService
  class << self

    # Create the provided PaymentSchedule on Stripe, using the Subscription API
    def create_stripe_subscription(payment_schedule_id, subscription, reservable_stp_id, setup_intent_id)
      stripe_key = Setting.get('stripe_secret_key')
      payment_schedule = PaymentSchedule.find(payment_schedule_id)
      first_item = payment_schedule.ordered_items.first

      # setup intent (associates the customer and the payment method)
      intent = Stripe::SetupIntent.retrieve(setup_intent_id, api_key: stripe_key)
      # subscription (recurring price)
      price = create_price(first_item.details['recurring'],
                           subscription.plan.stp_product_id,
                           nil, monthly: true)
      # other items (not recurring)
      items = subscription_invoice_items(payment_schedule, subscription, first_item, reservable_stp_id)

      stp_subscription = Stripe::Subscription.create({
                                                       customer: payment_schedule.invoicing_profile.user.stp_customer_id,
                                                       cancel_at: subscription.expiration_date.to_i,
                                                       promotion_code: payment_schedule.coupon&.code,
                                                       add_invoice_items: items,
                                                       items: [
                                                         { price: price[:id] }
                                                       ],
                                                       default_payment_method: intent[:payment_method]
                                                     }, { api_key: stripe_key })
      payment_schedule.update_attributes(stp_subscription_id: stp_subscription.id)
    end

    private

    def subscription_invoice_items(payment_schedule, subscription, first_item, reservable_stp_id)
      second_item = payment_schedule.ordered_items[1]

      items = []
      if first_item.amount != second_item.amount
        unless first_item.details['adjustment']&.zero?
          # adjustment: when dividing the price of the plan / months, sometimes it forces us to round the amount per month.
          # The difference is invoiced here
          p1 = create_price(first_item.details['adjustment'],
                            subscription.plan.stp_product_id,
                            "Price adjustment for payment schedule #{payment_schedule.id}")
          items.push(price: p1[:id])
        end
        unless first_item.details['other_items']&.zero?
          # when taking a subscription at the same time of a reservation (space, machine or training), the amount of the
          # reservation is invoiced here.
          p2 = create_price(first_item.details['other_items'],
                            reservable_stp_id,
                            "Reservations for payment schedule #{payment_schedule.id}")
          items.push(price: p2[:id])
        end
      end

      items
    end

    def create_price(amount, stp_product_id, name, monthly: false)
      params = {
        unit_amount: amount,
        currency: Setting.get('stripe_currency'),
        product: stp_product_id,
        nickname: name
      }
      params[:recurring] = { interval: 'month', interval_count: 1 } if monthly

      Stripe::Price.create(params, api_key: Setting.get('stripe_secret_key'))
    end
  end
end
