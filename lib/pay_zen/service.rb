# frozen_string_literal: true

require 'payment/service'
require 'pay_zen/charge'
require 'pay_zen/order'
require 'pay_zen/item'

# PayZen payement gateway
module PayZen; end

## create remote objects on PayZen
class PayZen::Service < Payment::Service
  def create_subscription(payment_schedule, order_id, *_args)
    first_item = payment_schedule.ordered_items.first

    order = PayZen::Order.new.get(order_id, operation_type: 'VERIFICATION')
    client = PayZen::Charge.new
    token_id = order['answer']['transactions'].first['paymentMethodToken']

    params = {
      amount: payzen_amount(first_item.details['recurring'].to_i),
      effect_date: first_item.due_date.iso8601,
      payment_method_token: token_id,
      rrule: rrule(payment_schedule),
      order_id: order_id
    }
    unless first_item.details['adjustment']&.zero? && first_item.details['other_items']&.zero?
      params[:initial_amount] = payzen_amount(first_item.amount)
      params[:initial_amount_number] = 1
    end
    pz_subscription = client.create_subscription(**params)

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

  def cancel_subscription(payment_schedule)
    pz_subscription = payment_schedule.gateway_subscription.retrieve

    order_client = PayZen::Order.new
    tr_client = PayZen::Transaction.new

    # first, we cancel all running transactions
    begin
      order = order_client.get(pz_subscription['answer']['orderId'])
      order['answer']['transactions'].select { |t| t['status'] == 'RUNNING' }.each do |t|
        tr_res = tr_client.cancel_or_refund(t['uuid'], amount: t['amount'], currency: t['currency'], resolution_mode: 'CANCELLATION_ONLY')
        raise "Cannot cancel transaction #{t['uuid']}" unless tr_res['answer']['detailedStatus'] == 'CANCELLED'
      end
    rescue PayzenError => e
      raise e unless e.details['errorCode'] == 'PSP_010' # ignore if no order
    end

    # then, we cancel the subscription
    begin
      sub_client = PayZen::Subscription.new
      res = sub_client.cancel(pz_subscription['answer']['subscriptionId'], pz_subscription['answer']['paymentMethodToken'])
    rescue PayzenError => e
      return true if e.details['errorCode'] == 'PSP_033' # recurring payment already canceled

      raise e
    end
    res['answer']['responseCode'].zero?
  end

  def process_payment_schedule_item(payment_schedule_item)
    pz_subscription = payment_schedule_item.payment_schedule.gateway_subscription.retrieve
    if pz_subscription['answer']['cancelDate'] && Time.zone.parse(pz_subscription['answer']['cancelDate']) <= Time.current
      # the subscription was canceled by the gateway => notify & update the status
      notify_payment_schedule_gateway_canceled(payment_schedule_item)
      payment_schedule_item.update(state: 'gateway_canceled')
      return
    end
    pz_order = payment_schedule_item.payment_schedule.gateway_order.retrieve
    transaction = pz_order['answer']['transactions'].last
    return unless transaction_matches?(transaction, payment_schedule_item)

    case transaction['status']
    when 'PAID'
      PaymentScheduleService.new.generate_invoice(payment_schedule_item,
                                                  payment_method: 'card',
                                                  payment_id: transaction['uuid'],
                                                  payment_type: 'PayZen::Transaction')
      payment_schedule_item.update(state: 'paid', payment_method: 'card')
      pgo = PaymentGatewayObject.find_or_initialize_by(item: payment_schedule_item)
      pgo.gateway_object = PayZen::Item.new('PayZen::Transaction', transaction['uuid'])
      pgo.save!
    when 'RUNNING'
      notify_payment_schedule_item_failed(payment_schedule_item)
      payment_schedule_item.update(state: transaction['detailedStatus'])
      pgo = PaymentGatewayObject.find_or_initialize_by(item: payment_schedule_item)
      pgo.gateway_object = PayZen::Item.new('PayZen::Transaction', transaction['uuid'])
      pgo.save!
    else
      notify_payment_schedule_item_error(payment_schedule_item)
      payment_schedule_item.update(state: 'error')
    end
  end

  def payzen_amount(amount)
    currency = Setting.get('payzen_currency')
    raise ConfigurationError, 'PayZen currency is not configured. Unable to process online payments.' if currency.nil?

    return amount / 100 if zero_decimal_currencies.any? { |s| s.casecmp(currency).zero? }
    return amount * 10 if three_decimal_currencies.any? { |s| s.casecmp(currency).zero? }

    amount
  end

  private

  def rrule(payment_schedule)
    count = payment_schedule.payment_schedule_items.count
    "RRULE:FREQ=MONTHLY;COUNT=#{count}"
  end

  # check if the given transaction matches the given PaymentScheduleItem
  def transaction_matches?(transaction, payment_schedule_item)
    transaction_date = Time.zone.parse(transaction['creationDate']).to_date

    transaction['amount'] == payment_schedule_item.amount &&
      transaction_date >= payment_schedule_item.due_date.to_date &&
      transaction_date <= payment_schedule_item.due_date.to_date + 7.days
  end

  # @see https://payzen.io/en-EN/payment-file/ips/list-of-supported-currencies.html
  def zero_decimal_currencies
    %w[KHR JPY KRW XOF XPF]
  end

  def three_decimal_currencies
    %w[KWD TND]
  end
end
