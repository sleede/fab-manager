# frozen_string_literal: true

# API Controller for accessing PayZen API endpoints through the front-end app
class API::PayzenController < API::PaymentsController
  require 'pay_zen/charge'
  require 'pay_zen/order'
  require 'pay_zen/helper'

  def sdk_test
    str = 'fab-manager'

    client = PayZen::Charge.new(base_url: params[:base_url], username: params[:username], password: params[:password])
    res = client.sdk_test(str)

    @status = (res['answer']['value'] == str)
  rescue SocketError
    @status = false
  end

  def create_payment
    amount = card_amount
    @id = PayZen::Helper.generate_ref(cart_items_params, params[:customer])

    client = PayZen::Charge.new
    @result = client.create_payment(amount: amount[:amount],
                                    order_id: @id,
                                    customer: PayZen::Helper.generate_customer(params[:customer_id]))
    @result
  end

  def confirm_payment
    render(json: { error: 'Bad gateway or online payment is disabled' }, status: :bad_gateway) and return unless PayZen::Helper.enabled?

    client = PayZen::Order.new
    order = client.get(params[:order_id])

    amount = card_amount

    if order[:transactions].first.status == 'PAID'
      if params[:cart_items][:reservation]
        res = on_reservation_success(intent, amount[:details])
      elsif params[:cart_items][:subscription]
        res = on_subscription_success(intent, amount[:details])
      end
    end

    render generate_payment_response(intent, res)
  rescue StandardError => e
    render json: e, status: :unprocessable_entity
  end

  private

  def on_reservation_success(intent, details)
    @reservation = Reservation.new(reservation_params)
    payment_method = params[:cart_items][:reservation][:payment_method] || 'stripe'
    user_id = if current_user.admin? || current_user.manager?
                params[:cart_items][:reservation][:user_id]
              else
                current_user.id
              end
    is_reserve = Reservations::Reserve.new(user_id, current_user.invoicing_profile.id)
                                      .pay_and_save(@reservation,
                                                    payment_details: details,
                                                    intent_id: intent.id,
                                                    schedule: params[:cart_items][:reservation][:payment_schedule],
                                                    payment_method: payment_method)
    if intent.class == Stripe::PaymentIntent
      Stripe::PaymentIntent.update(
        intent.id,
        { description: "Invoice reference: #{@reservation.invoice.reference}" },
        { api_key: Setting.get('stripe_secret_key') }
      )
    end

    if is_reserve
      SubscriptionExtensionAfterReservation.new(@reservation).extend_subscription_if_eligible

      { template: 'api/reservations/show', status: :created, location: @reservation }
    else
      { json: @reservation.errors, status: :unprocessable_entity }
    end
  end

  def on_subscription_success(intent, details)
    @subscription = Subscription.new(subscription_params)
    user_id = if current_user.admin? || current_user.manager?
                params[:cart_items][:subscription][:user_id]
              else
                current_user.id
              end
    is_subscribe = Subscriptions::Subscribe.new(current_user.invoicing_profile.id, user_id)
                                           .pay_and_save(@subscription,
                                                         payment_details: details,
                                                         intent_id: intent.id,
                                                         schedule: params[:cart_items][:subscription][:payment_schedule],
                                                         payment_method: 'stripe')
    if intent.class == Stripe::PaymentIntent
      Stripe::PaymentIntent.update(
        intent.id,
        { description: "Invoice reference: #{@subscription.invoices.first.reference}" },
        { api_key: Setting.get('stripe_secret_key') }
      )
    end

    if is_subscribe
      { template: 'api/subscriptions/show', status: :created, location: @subscription }
    else
      { json: @subscription.errors, status: :unprocessable_entity }
    end
  end
end
