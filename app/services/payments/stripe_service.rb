# frozen_string_literal: true

# Provides methods for pay cart by Stripe
class Payments::StripeService
  require 'stripe/service'
  include Payments::PaymentConcern

  def payment(order, coupon_code, payment_id)
    amount = debit_amount(order, coupon_code)

    raise Cart::ZeroPriceError if amount.zero?

    # Create the PaymentIntent
    intent = Stripe::PaymentIntent.create(
      {
        payment_method: payment_id,
        amount: Stripe::Service.new.stripe_amount(amount),
        currency: Setting.get('stripe_currency'),
        confirmation_method: 'manual',
        confirm: true,
        customer: order.statistic_profile.user.payment_gateway_object.gateway_object_id
      }, { api_key: Setting.get('stripe_secret_key') }
    )

    if intent&.status == 'succeeded'
      o = payment_success(order, coupon_code, 'card', intent.id, intent.class.name)
      return { order: o }
    end

    if intent&.status == 'requires_action' && intent&.next_action&.type == 'use_stripe_sdk'
      { order: order, payment: { requires_action: true, payment_intent_client_secret: intent.client_secret,
                                 type: 'payment' } }
    end
  end

  def confirm_payment(order, coupon_code, payment_id)
    intent = Stripe::PaymentIntent.confirm(payment_id, {}, { api_key: Setting.get('stripe_secret_key') })
    if intent&.status == 'succeeded'
      o = payment_success(order, coupon_code, 'card', intent.id, intent.class.name)
      { order: o }
    else
      order.update(state: 'payment_failed')
      { order: order, payment: { error: { statusText: 'payment failed' } } }
    end
  end
end
