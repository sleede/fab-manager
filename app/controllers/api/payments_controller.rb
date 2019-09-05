# frozen_string_literal: true

# API Controller for handling payments process in the front-end
class API::PaymentsController < API::ApiController
  before_action :authenticate_user!

  # TODO https://stripe.com/docs/payments/payment-intents/web-manual
  def confirm_payment
    data = JSON.parse(request.body.read.to_s)

    begin
      if data['payment_method_id']
        # Create the PaymentIntent
        intent = Stripe::PaymentIntent.create(
          payment_method: data['payment_method_id'],
          amount: 1099,
          currency: 'usd',
          confirmation_method: 'manual',
          confirm: true
        )
      elsif data['payment_intent_id']
        intent = Stripe::PaymentIntent.confirm(data['payment_intent_id'])
      end
    rescue Stripe::CardError => e
      # Display error on client
      return [200, { error: e.message }.to_json]
    end

    return generate_payment_response(intent)
  end
end