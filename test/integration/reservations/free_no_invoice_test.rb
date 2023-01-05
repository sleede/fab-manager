# frozen_string_literal: true

require 'test_helper'

module Reservations; end

class Reservations::FreeNoInvoiceTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.members.first
    @machine = Machine.find(6)
    @availability = @machine.availabilities.first
    @admin = User.with_role(:admin).first
    login_as(@admin, scope: :user)
  end

  test 'free reservation does not generate an invoice' do
    Setting.set('prevent_invoices_zero', 'true')

    reservations_count = Reservation.count
    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    users_credit_count = UsersCredit.count
    subscriptions_count = Subscription.count

    post '/api/local_payment/confirm_payment', params: {
      customer_id: @user.id,
      items: [
        {
          reservation: {
            reservable_id: @machine.id,
            reservable_type: @machine.class.name,
            slots_reservations_attributes: [
              {
                slot_id: @availability.slots.first.id,
                offered: true
              }
            ]
          }
        }
      ]
    }.to_json, headers: default_headers

    # general assertions
    assert_equal 201, response.status
    assert_equal reservations_count + 1, Reservation.count
    assert_equal invoice_count, Invoice.count
    assert_equal invoice_items_count, InvoiceItem.count
    assert_equal users_credit_count, UsersCredit.count
    assert_equal subscriptions_count, Subscription.count
  end
end
