# frozen_string_literal: true

# API Controller for handling payments process in the front-end
class API::PaymentsController < API::ApiController
  before_action :authenticate_user!

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

    render generate_payment_response(intent)
  end

  private

  def generate_payment_response(intent)
    if intent.status == 'requires_action' && intent.next_action.type == 'use_stripe_sdk'
      # Tell the client to handle the action
      {
        status: 200,
        json: {
          requires_action: true,
          payment_intent_client_secret: intent.client_secret
        }
      }
    elsif intent.status == 'succeeded'
      # The payment didn’t need any additional actions and is completed!
      # Handle post-payment fulfillment
      { status: 200, json: { success: true } }
    else
      # Invalid status
      { status: 500, json: { error: 'Invalid PaymentIntent status' } }
    end
  end
end