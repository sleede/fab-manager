# frozen_string_literal: true

require 'pay_zen/client'

# PayZen PCI endpoints
module PayZen::PCI; end

# PCI/Charge/* endpoints of the PayZen REST API
class PayZen::PCI::Charge < PayZen::Client
  def initialize(base_url: nil, username: nil, password: nil)
    super(base_url: base_url, username: username, password: password)
  end

  ##
  # @see https://payzen.io/en-EN/rest/V4.0/api/playground/PCI/Charge/CreatePayment/
  ##
  def create_payment(amount: 0,
                     currency: Setting.get('payzen_currency'),
                     order_id: nil,
                     form_action: 'PAYMENT',
                     contrib: "fab-manager #{Version.current}",
                     customer: nil,
                     device: nil,
                     payment_forms: nil)
    post('/PCI/Charge/CreatePayment',
         amount: amount,
         currency: currency,
         orderId: order_id,
         formAction: form_action,
         contrib: contrib,
         customer: customer,
         device: device,
         paymentForms: payment_forms)
  end
end
