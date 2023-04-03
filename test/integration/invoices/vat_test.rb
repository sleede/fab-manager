# frozen_string_literal: true

require 'test_helper'

module Invoices; end

class Invoices::VATTest < ActionDispatch::IntegrationTest
  include ActionView::Helpers::NumberHelper

  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'renamed VAT' do
    user = User.find_by(username: 'vlonchamp')
    plan = Plan.find(5)

    Setting.set('invoice_VAT-active', true)
    Setting.set('invoice_VAT-name', 'TVQ+TPS')

    post '/api/local_payment/confirm_payment', params: {
      customer_id: user.id,
      items: [
        {
          subscription: {
            plan_id: plan.id
          }
        }
      ]
    }.to_json, headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    invoice = Invoice.last
    assert_invoice_pdf invoice do |lines|
      vat_line = I18n.t('invoices.including_VAT_RATE',
                        **{ RATE: Setting.get('invoice_VAT-rate'),
                            AMOUNT: number_to_currency(invoice.total / 100.00),
                            NAME: 'TVQ+TPS' })
      assert(lines.any? { |l| /#{Regexp.escape(vat_line)}/.match(l) })
    end
  end
end
