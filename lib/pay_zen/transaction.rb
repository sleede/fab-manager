# frozen_string_literal: true

require 'pay_zen/client'

# Transaction/* endpoints of the PayZen REST API
class PayZen::Transaction < PayZen::Client
  def initialize(base_url: nil, username: nil, password: nil)
    super(base_url: base_url, username: username, password: password)
  end

  ##
  # @see https://payzen.io/fr-FR/rest/V4.0/api/playground/Transaction/Get/
  ##
  def get(uuid)
    post('/Transaction/Get/', uuid: uuid)
  end

  ##
  # @see https://payzen.io/fr-FR/rest/V4.0/api/playground/Transaction/CancelOrRefund
  ##
  def cancel_or_refund(uuid,
                       amount: 0,
                       currency: Setting.get('payzen_currency'),
                       resolution_mode: nil,
                       comment: nil)
    post('/Transaction/CancelOrRefund/', uuid: uuid, amount: amount, currency: currency, resolutionMode: resolution_mode, comment: comment)
  end
end
