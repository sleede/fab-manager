# frozen_string_literal: true

require 'test_helper'

class AccountingServiceTest < ActionDispatch::IntegrationTest
  def setup
    @vlonchamp = User.find_by(username: 'vlonchamp')
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'build accounting lines from an invoice' do
    # Let's make a reservation to create a new invoice
    machine = Machine.find(3)
    availability = machine.availabilities.first
    plan = Plan.find(5)

    # enable the VAT
    Setting.set('invoice_VAT-active', true)
    Setting.set('invoice_VAT-rate', 19.6)

    post '/api/local_payment/confirm_payment', params: {
      customer_id: @vlonchamp.id,
      coupon_code: 'GIME3EUR',
      items: [
        {
          reservation: {
            reservable_id: machine.id,
            reservable_type: machine.class.name,
            slots_reservations_attributes: [
              {
                slot_id: availability.slots.first.id
              }
            ]
          }
        },
        {
          subscription: {
            plan_id: plan.id
          }
        }
      ]
    }.to_json, headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_equal Mime[:json], response.content_type

    # Build the accounting lines
    invoice_id = Invoice.last.id
    invoice = Invoice.find(invoice_id)
    service = Accounting::AccountingService.new
    service.build_from_invoices(Invoice.where(id: invoice_id))

    lines = AccountingLine.where(invoice_id: invoice_id)
    assert 5, lines.count

    # Check the wallet line
    assert 2, lines.filter { |l| l.line_type == 'client' }.count
    client_wallet = lines.find { |l| l.account_code == Setting.get('accounting_wallet_client_code') }
    assert_not_nil client_wallet
    assert_equal 1000, client_wallet&.debit
    # Check the local payment line
    client_other = lines.find { |l| l.account_code == Setting.get('accounting_other_client_code') }
    assert_not_nil client_other
    assert_equal invoice.total - 1000, client_other&.debit

    # Check the machine reservation line
    assert 2, lines.filter { |l| l.line_type == 'item' }.count
    item_machine = lines.find { |l| l.account_code == Setting.get('accounting_Machine_code') }
    assert_not_nil item_machine
    assert_equal invoice.main_item.net_amount, item_machine&.credit
    # Check the subscription line
    item_suscription = lines.find { |l| l.account_code == Setting.get('accounting_subscription_code') }
    assert_not_nil item_suscription
    assert_equal invoice.other_items.last.net_amount, item_suscription&.credit

    # Check the VAT line
    vat_service = VatHistoryService.new
    vat_rate_groups = vat_service.invoice_vat(invoice)
    assert 1, lines.filter { |l| l.line_type == 'vat' }.count
    vat_line = lines.find { |l| l.account_code == Setting.get('accounting_VAT_code') }
    assert_not_nil vat_line
    assert_equal vat_rate_groups.values.pluck(:total_vat).sum, vat_line&.credit
  end
end
