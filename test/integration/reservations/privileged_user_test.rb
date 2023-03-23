# frozen_string_literal: true

require 'test_helper'

module Reservations; end

class Reservations::PrivilegedUserTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.with_role(:admin).first
    login_as(@admin, scope: :user)
  end

  test 'admin cannot reserves for himself with local payment' do
    machine = Machine.find(6)
    availability = machine.availabilities.first

    reservations_count = Reservation.count
    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    users_credit_count = UsersCredit.count

    post '/api/local_payment/confirm_payment', params: {
      customer_id: @admin.id,
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
        }
      ]
    }.to_json, headers: default_headers

    # general assertions
    assert_equal 403, response.status
    assert_equal reservations_count, Reservation.count
    assert_equal invoice_count, Invoice.count
    assert_equal invoice_items_count, InvoiceItem.count
    assert_equal users_credit_count, UsersCredit.count

    # subscription assertions
    assert_equal 0, @admin.subscriptions.count
    assert_nil @admin.subscribed_plan
  end

  test 'admin reserves a machine for himself with success' do
    machine = Machine.find(6)
    availability = machine.availabilities.first

    reservations_count = Reservation.count
    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    users_credit_count = UsersCredit.count
    subscriptions_count = Subscription.count

    VCR.use_cassette('reservations_create_for_machine_as_admin_for_himself_success') do
      post '/api/stripe/confirm_payment',
           params: {
             payment_method_id: stripe_payment_method,
             cart_items: {
               customer_id: @admin.id,
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
                 }
               ]
             }
           }.to_json, headers: default_headers
    end

    # general assertions
    assert_equal 201, response.status
    assert_equal reservations_count + 1, Reservation.count
    assert_equal invoice_count + 1, Invoice.count
    assert_equal invoice_items_count + 1, InvoiceItem.count
    assert_equal users_credit_count, UsersCredit.count
    assert_equal subscriptions_count, Subscription.count

    # subscription assertions
    assert_equal 0, @admin.subscriptions.count
    assert_nil @admin.subscribed_plan

    # reservation assertions
    reservation = Reservation.last

    assert reservation.original_invoice
    assert_equal 1, reservation.original_invoice.invoice_items.count

    # invoice_items assertions
    invoice_item = InvoiceItem.last

    assert_equal machine.prices.find_by(group_id: @admin.group_id, plan_id: nil).amount, invoice_item.amount
    assert invoice_item.check_footprint

    # invoice assertions
    item = InvoiceItem.find_by(object: reservation)
    invoice = item.invoice
    assert_invoice_pdf invoice

    assert_not invoice.payment_gateway_object.blank?
    assert_not invoice.total.blank?
    assert invoice.check_footprint

    # notification
    assert_not_empty Notification.where(attached_object: reservation)
  end
end
