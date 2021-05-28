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
    cart = shopping_cart
    amount = debit_amount(cart)
    @id = PayZen::Helper.generate_ref(params[:cart_items], params[:customer_id])

    client = PayZen::Charge.new
    @result = client.create_payment(amount: amount[:amount],
                                    order_id: @id,
                                    customer: PayZen::Helper.generate_customer(params[:customer_id], current_user.id, params[:cart_items]))
    error_handling
  end

  def create_token
    @id = PayZen::Helper.generate_ref(params[:cart_items], params[:customer_id])
    client = PayZen::Charge.new
    @result = client.create_token(order_id: @id,
                                  customer: PayZen::Helper.generate_customer(params[:customer_id], current_user.id, params[:cart_items]))
    error_handling
  end

  def check_hash
    @result = PayZen::Helper.check_hash(params[:algorithm], params[:hash_key], params[:hash], params[:data])
  end

  def confirm_payment
    render(json: { error: 'Bad gateway or online payment is disabled' }, status: :bad_gateway) and return unless PayZen::Helper.enabled?

    client = PayZen::Order.new
    order = client.get(params[:order_id], operation_type: 'DEBIT')

    cart = shopping_cart

    if order['answer']['transactions'].first['status'] == 'PAID'
      render on_payment_success(params[:order_id], cart)
    else
      render json: order['answer'], status: :unprocessable_entity
    end
  rescue StandardError => e
    render json: e, status: :unprocessable_entity
  end

  private

  def on_payment_success(order_id, cart)
    super(order_id, 'PayZen::Order', cart)
  end

  def error_handling
    return unless @result['status'] == 'ERROR'

    render json: { error: @result['answer']['detailedErrorMessage'] || @result['answer']['errorMessage'] }, status: :unprocessable_entity
  end
end
