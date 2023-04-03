# frozen_string_literal: true

require 'test_helper'

module Events; end

class Events::AsUserTest < ActionDispatch::IntegrationTest
  test 'reserve event with many prices and payment means and VAT' do
    vlonchamp = User.find_by(username: 'vlonchamp')
    login_as(vlonchamp, scope: :user)

    radio = Event.find(4)
    slot = radio.availability.slots.first

    reservations_count = Reservation.count
    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    users_credit_count = UsersCredit.count
    wallet_transactions_count = WalletTransaction.count

    # Enable the VAT at 19.6%
    Setting.set('invoice_VAT-active', true)
    Setting.set('invoice_VAT-rate', '19.6')

    # Reserve the 'radio' event
    VCR.use_cassette('reserve_event_with_many_prices_and_payment_means') do
      post '/api/stripe/confirm_payment',
           params: {
             payment_method_id: stripe_payment_method,
             cart_items: {
               customer_id: User.find_by(username: 'vlonchamp').id,
               items: [
                 {
                   reservation: {
                     reservable_id: radio.id,
                     reservable_type: 'Event',
                     nb_reserve_places: 2,
                     slots_reservations_attributes: [
                       {
                         slot_id: slot.id,
                         offered: false
                       }
                     ],
                     tickets_attributes: [
                       {
                         event_price_category_id: radio.event_price_categories[0].id,
                         booked: 2
                       },
                       {
                         event_price_category_id: radio.event_price_categories[1].id,
                         booked: 2
                       }
                     ]
                   }
                 }
               ],
               coupon_code: 'SUNNYFABLAB'
             }
           }.to_json, headers: default_headers
    end

    vlonchamp.wallet.reload

    # general assertions
    assert_equal 201, response.status
    assert_equal reservations_count + 1, Reservation.count
    assert_equal invoice_count + 1, Invoice.count
    assert_equal invoice_items_count + 1, InvoiceItem.count
    assert_equal users_credit_count, UsersCredit.count
    assert_equal wallet_transactions_count + 1, WalletTransaction.count

    # reservation assertions
    reservation = Reservation.last

    assert reservation.original_invoice
    assert_equal 1, reservation.original_invoice.invoice_items.count

    # invoice assertions
    invoice = reservation.original_invoice

    assert_not invoice.payment_gateway_object.blank?
    assert_not invoice.total.blank?
    assert_equal 43_350, invoice.total # total minus coupon

    # invoice_items assertions
    ## reservation
    reservation_item = invoice.invoice_items.first

    assert_not_nil reservation_item
    assert_equal 51_000, reservation_item.amount # full total

    # invoice assertions
    item = InvoiceItem.find_by(object: reservation)
    invoice = item.invoice
    assert_invoice_pdf invoice

    VCR.use_cassette('reserve_event_with_many_prices_and_payment_means_retrieve_invoice_from_stripe') do
      stp_intent = invoice.payment_gateway_object.gateway_object.retrieve
      assert_equal stp_intent.amount, (invoice.total - invoice.wallet_amount) # total minus coupon minus wallet = amount really paid
    end

    # wallet assertions
    assert_equal vlonchamp.wallet.amount, 0
    assert_equal vlonchamp.wallet.wallet_transactions.count, 2
    transaction = vlonchamp.wallet.wallet_transactions.last
    assert_equal transaction.transaction_type, 'debit'
    assert_equal transaction.amount, 10
    assert_equal transaction.amount, invoice.wallet_amount / 100.0

    # notifications
    assert_not_empty Notification.where(attached_object: reservation)
    assert_not_empty Notification.where(attached_object: invoice)
  end
end
