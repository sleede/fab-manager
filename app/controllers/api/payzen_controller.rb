# frozen_string_literal: true

# API Controller for accessing PayZen API endpoints through the front-end app
class API::PayzenController < API::ApiController
  before_action :authenticate_user!
  require 'pay_zen/charge'

  def sdk_test
    str = 'fab-manager'

    client = PayZen::Charge.new(base_url: params[:base_url], username: params[:username], password: params[:password])
    res = client.sdk_test(str)

    puts res
    @status = res&.answer&.value == str
  end
end
