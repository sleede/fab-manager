# frozen_string_literal: true

# API Controller for accessing PayZen API endpoints through the front-end app
class API::PayzenController < API::PaymentsController
  require 'pay_zen/charge'
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
                                    customer: { reference: params[:customer][:id], email: params[:customer][:email] })
    @result
  end
end
