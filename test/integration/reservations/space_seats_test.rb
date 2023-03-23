# frozen_string_literal: true

require 'test_helper'

module Reservations; end

class Reservations::SpaceSeatsTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.admins.first
    @user1 = User.find(5)
    @user2 = User.find(2)
    @user3 = User.find(4)
  end

  test 'create a space availability and reserve it multiple times' do
    login_as(@admin, scope: :user)

    space = Space.first

    date = 1.day.from_now.change(hour: 8, min: 0, sec: 0)

    post '/api/availabilities',
         params: {
           availability: {
             start_at: date.iso8601,
             end_at: (date + 1.hour).iso8601,
             available_type: 'space',
             tag_ids: [],
             is_recurrent: false,
             slot_duration: 60,
             space_ids: [space.id],
             nb_total_places: 2,
             occurrences: [
               { start_at: date.iso8601, end_at: (date + 1.hour).iso8601 }
             ]
           }
         }

    # Check response format & status
    assert_equal 201, response.status
    assert_match Mime[:json].to_s, response.content_type

    # Check the availability
    res = json_response(response.body)
    availability = Availability.find(res[:id])
    slot = availability.slots.first

    ### FIRST RESERVATION

    reservations_count = Reservation.count
    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    users_credit_count = UsersCredit.count
    subscriptions_count = Subscription.count

    post '/api/local_payment/confirm_payment',
         params: {
           customer_id: @user1.id,
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
         }.to_json, headers: default_headers

    # general assertions
    assert_equal 201, response.status
    assert_equal reservations_count + 1, Reservation.count
    assert_equal invoice_count + 1, Invoice.count
    assert_equal invoice_items_count + 1, InvoiceItem.count
    assert_equal users_credit_count, UsersCredit.count
    assert_equal subscriptions_count, Subscription.count

    # subscription assertions
    assert_equal 0, @user1.subscriptions.count
    assert_nil @user1.subscribed_plan

    # reservation assertions
    reservation = Reservation.last

    assert reservation.original_invoice
    assert_equal 1, reservation.original_invoice.invoice_items.count

    # invoice_items assertions
    invoice_item = InvoiceItem.last

    assert_equal space.prices.find_by(group_id: @user1.group_id, plan_id: nil).amount, invoice_item.amount
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

    # place cache
    slot.reload
    cached = slot.places.detect { |p| p['reservable_id'] == space.id && p['reservable_type'] == space.class.name }
    assert_not_nil cached
    assert_equal 1, cached['reserved_places']
    assert_includes cached['user_ids'], @user1.id

    ### SECOND RESERVATION
    login_as(@user2, scope: :user)

    VCR.use_cassette('reservations_space_seats_user2') do
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
    assert_equal reservations_count + 2, Reservation.count
    assert_equal invoice_count + 2, Invoice.count
    assert_equal invoice_items_count + 2, InvoiceItem.count
    assert_equal users_credit_count, UsersCredit.count
    assert_equal subscriptions_count, Subscription.count

    # subscription assertions
    assert_equal 0, @user2.subscriptions.count
    assert_nil @user2.subscribed_plan

    # reservation assertions
    reservation = Reservation.last

    assert reservation.original_invoice
    assert_equal 1, reservation.original_invoice.invoice_items.count

    # invoice_items assertions
    invoice_item = InvoiceItem.last

    assert_equal space.prices.find_by(group_id: @user2.group_id, plan_id: nil).amount, invoice_item.amount
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
    assert_equal 2, cached['reserved_places']
    assert_includes cached['user_ids'], @user2.id

    ### THIRD RESERVATION
    login_as(@user3, scope: :user)

    VCR.use_cassette('reservations_space_seats_user3') do
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
    assert_equal 422, response.status
    assert_equal reservations_count + 2, Reservation.count
    assert_equal invoice_count + 2, Invoice.count
    assert_equal invoice_items_count + 2, InvoiceItem.count
    assert_equal users_credit_count, UsersCredit.count
    assert_equal subscriptions_count, Subscription.count

    # subscription assertions
    assert_equal 1, @user3.subscriptions.count
    assert_not_nil @user3.subscribed_plan

    # assert nothing was created
    reservation = Reservation.last
    invoice = Invoice.last
    invoice_item = InvoiceItem.last

    assert_not_equal reservation.user.id, @user3.id
    assert_not_equal invoice.user.id, @user3.id
    assert_not_equal space.prices.find_by(group_id: @user3.group_id, plan_id: nil).amount, invoice_item.amount

    # place cache
    slot.reload
    cached = slot.places.detect { |p| p['reservable_id'] == space.id && p['reservable_type'] == space.class.name }
    assert_not_nil cached
    assert_equal 2, cached['reserved_places']
    assert_not_includes cached['user_ids'], @user3.id
  end
end
