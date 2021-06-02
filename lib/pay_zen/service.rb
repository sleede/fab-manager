# frozen_string_literal: true

require 'payment/service'
require 'pay_zen/charge'
require 'pay_zen/order'

# PayZen payement gateway
module PayZen; end

## create remote objects on PayZen
class PayZen::Service < Payment::Service
  def create_subscription(payment_schedule, order_id)
    first_item = payment_schedule.ordered_items.first

    order = PayZen::Order.new.get(order_id, operation_type: 'VERIFICATION')
    client = PayZen::Charge.new
    token_id = order['answer']['transactions'].first['paymentMethodToken']

    params = {
      amount: first_item.details['recurring'].to_i,
      effect_date: first_item.due_date.iso8601,
      payment_method_token: token_id,
      rrule: rrule(payment_schedule),
      order_id: order_id
    }
    unless first_item.details['adjustment']&.zero?
      params[:initial_amount] = first_item.amount
      params[:initial_amount_number] = 1
    end
    pz_subscription = client.create_subscription(params)

    # save payment token
    pgo_tok = PaymentGatewayObject.new(
      gateway_object_id: token_id,
      gateway_object_type: 'PayZen::Token',
      item: payment_schedule
    )
    pgo_tok.save!

    # save payzen subscription
    pgo_sub = PaymentGatewayObject.new(
      gateway_object_id: pz_subscription['answer']['subscriptionId'],
      gateway_object_type: 'PayZen::Subscription',
      item: payment_schedule,
      payment_gateway_object_id: pgo_tok.id
    )
    pgo_sub.save!
  end

  private

  def rrule(payment_schedule)
    count = payment_schedule.payment_schedule_items.count
    "RRULE:FREQ=MONTHLY;COUNT=#{count}"
  end
end
