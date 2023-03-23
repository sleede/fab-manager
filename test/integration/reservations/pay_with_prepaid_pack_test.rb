# frozen_string_literal: true

require 'test_helper'

module Reservations; end

class Reservations::PayWithPrepaidPackTest < ActionDispatch::IntegrationTest
  setup do
    @acamus = User.find_by(username: 'acamus')
  end

  test 'user reserves a machine and pay by prepaid pack with success' do
    login_as(@acamus, scope: :user)

    machine = Machine.find(1)
    availability = Availability.find(4)

    reservations_count = Reservation.count
    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count

    VCR.use_cassette('reservations_create_for_machine_with_prepaid_pack_success') do
      post '/api/local_payment/confirm_payment',
           params: {
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
    end

    # general assertions
    assert_equal 201, response.status
    assert_equal reservations_count + 1, Reservation.count
    assert_equal invoice_count + 1, Invoice.count
    assert_equal invoice_items_count + 1, InvoiceItem.count

    # reservation assertions
    reservation = Reservation.last

    assert reservation.original_invoice
    assert_equal 1, reservation.original_invoice.invoice_items.count

    # invoice_items assertions
    invoice_item = InvoiceItem.last

    assert_equal invoice_item.amount, 0
    assert invoice_item.check_footprint

    # invoice assertions
    item = InvoiceItem.find_by(object: reservation)
    invoice = item.invoice
    assert_invoice_pdf invoice

    assert invoice.payment_gateway_object.blank?
    assert_not invoice.total.blank?
    assert invoice.check_footprint

    # notification
    assert_not_empty Notification.where(attached_object: reservation)

    # prepaid pack
    minutes_available = PrepaidPackService.minutes_available(@acamus, machine)
    assert_equal minutes_available, 540
  end
end
