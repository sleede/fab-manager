# frozen_string_literal: true

# Provides methods for pay cart by PayZen
class Payments::PayzenService
  require 'pay_zen/helper'
  require 'pay_zen/order'
  require 'pay_zen/charge'
  require 'pay_zen/service'
  include Payments::PaymentConcern

  def payment(order)
    amount = debit_amount(order)

    raise Cart::ZeroPriceError if amount.zero?

    id = PayZen::Helper.generate_ref(order, order.statistic_profile.user.id)

    client = PayZen::Charge.new
    result = client.create_payment(amount: PayZen::Service.new.payzen_amount(amount),
                                   order_id: id,
                                   customer: PayZen::Helper.generate_customer(order.statistic_profile.user.id,
                                                                              order.statistic_profile.user.id, order))
    { order: order, payment: { formToken: result['answer']['formToken'], orderId: id } }
  end

  def confirm_payment(order, payment_id)
    client = PayZen::Order.new
    payzen_order = client.get(payment_id, operation_type: 'DEBIT')

    if payzen_order['answer']['transactions'].any? { |transaction| transaction['status'] == 'PAID' }
      o = payment_success(order, 'card', payment_id, 'PayZen::Order')
      { order: o }
    else
      order.update(payment_state: 'failed')
      { order: order, payment: { error: { statusText: payzen_order['answer'] } } }
    end
  end
end
