# frozen_string_literal: true

require 'pay_zen/client'

# Charge/* endpoints of the PayZen REST API
class PayZen::Charge < PayZen::Client
  def initialize(base_url: nil, username: nil, password: nil)
    super(base_url: base_url, username: username, password: password)
  end

  ##
  # @see https://payzen.io/fr-FR/rest/V4.0/api/playground/Charge/SDKTest/
  ##
  def sdk_test(value)
    post('/Charge/SDKTest', value: value)
  end
end

