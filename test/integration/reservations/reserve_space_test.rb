# frozen_string_literal: true

require 'test_helper'

module Reservations; end

class Reservations::ReserveSpaceTest < ActionDispatch::IntegrationTest
  setup do
    @user_without_subscription = User.members.without_subscription.first
  end

  test 'user reserves a space with success' do
    login_as(@user_without_subscription, scope: :user)

    space = Space.first
    availability = space.availabilities.first
    slot = availability.slots.first

    reservations_count = Reservation.count
    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    users_credit_count = UsersCredit.count
    subscriptions_count = Subscription.count

    VCR.use_cassette('reservations_create_for_space_success') do
      post '/api/stripe/confirm_payment',
           params: {
             payment_method_id: stripe_payment_method,
             cart_items: {
               items: [
                 {
                   reservation: {
                     reservable_id: space.id,
                     reservable_type: space.class.name,
                     slots_reservations_attributes: [
                       {
                         slot_id: slot.id
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
    assert_equal 0, @user_without_subscription.subscriptions.count
    assert_nil @user_without_subscription.subscribed_plan

    # reservation assertions
    reservation = Reservation.last

    assert reservation.original_invoice
    assert_equal 1, reservation.original_invoice.invoice_items.count

    # invoice_items assertions
    invoice_item = InvoiceItem.last

    assert_equal space.prices.find_by(group_id: @user_without_subscription.group_id, plan_id: nil).amount, invoice_item.amount
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

    # place cache
    slot.reload
    cached = slot.places.detect { |p| p['reservable_id'] == space.id && p['reservable_type'] == space.class.name }
    assert_not_nil cached
    assert_equal 1, cached['reserved_places']
    assert_includes cached['user_ids'], @user_without_subscription.id
  end
end
