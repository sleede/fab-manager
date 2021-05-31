# frozen_string_literal: true

require 'test_helper'

module Reservations; end

class Reservations::RestrictedTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.with_role(:admin).first
    @pdurand = User.find(3) # user with subscription to plan 2
    @jdupont = User.find(2) # user without subscription
  end

  test 'reserve slot restricted to subscribers with success' do
    login_as(@admin, scope: :user)

    reservations_count = Reservation.count
    availabilities_count = Availability.count
    invoices_count = Invoice.count
    slots_count = Slot.count

    # first, create the restricted availability
    date = 4.days.from_now.utc.change(hour: 8, min: 0, sec: 0)
    post '/api/availabilities',
         params: {
           availability: {
             start_at: date.iso8601,
             end_at: (date + 6.hours).iso8601,
             available_type: 'machines',
             slot_duration: 60,
             machine_ids: [2],
             occurrences: [
               { start_at: date.iso8601, end_at: (date + 6.hours).iso8601 }
             ],
             plan_ids: [2]
           }
         }

    assert_equal 201, response.status

    # Check the id
    availability = json_response(response.body)
    assert_not_nil availability[:id], 'availability ID was unexpectedly nil'

    assert_equal availabilities_count + 1, Availability.count

    # change connected user
    login_as(@pdurand, scope: :user)

    # book a reservation
    VCR.use_cassette('reservations_create_for_restricted_slot_success') do
      post '/api/stripe/confirm_payment',
           params: {
             payment_method_id: stripe_payment_method,
             cart_items: {
               items: [
                 {
                   reservation: {
                     reservable_id: 2,
                     reservable_type: 'Machine',
                     slots_attributes: [
                       {
                         start_at: availability[:start_at],
                         end_at: (DateTime.parse(availability[:start_at]) + 1.hour).to_s(:iso8601),
                         availability_id: availability[:id]
                       }
                     ]
                   }
                 }
               ]
             }
           }.to_json, headers: default_headers
    end

    assert_equal 201, response.status

    assert_equal reservations_count + 1, Reservation.count
    assert_equal invoices_count + 1, Invoice.count
    assert_equal slots_count + 1, Slot.count
  end

  test 'unable to reserve slot restricted to subscribers' do
    login_as(@admin, scope: :user)

    reservations_count = Reservation.count
    availabilities_count = Availability.count
    invoices_count = Invoice.count
    slots_count = Slot.count

    # first, create the restricted availability
    date = 4.days.from_now.utc.change(hour: 8, min: 0, sec: 0)
    post '/api/availabilities',
         params: {
           availability: {
             start_at: date.iso8601,
             end_at: (date + 6.hours).iso8601,
             available_type: 'machines',
             slot_duration: 60,
             machine_ids: [2],
             occurrences: [
               { start_at: date.iso8601, end_at: (date + 6.hours).iso8601 }
             ],
             plan_ids: [2]
           }
         }

    assert_equal 201, response.status

    # Check the id
    availability = json_response(response.body)
    assert_not_nil availability[:id], 'availability ID was unexpectedly nil'

    assert_equal availabilities_count + 1, Availability.count

    # change connected user
    login_as(@jdupont, scope: :user)

    # book a reservation
    VCR.use_cassette('reservations_create_for_restricted_slot_fails') do
      post '/api/stripe/confirm_payment',
           params: {
             payment_method_id: stripe_payment_method,
             cart_items: {
               items: [
                 {
                   reservation: {
                     reservable_id: 2,
                     reservable_type: 'Machine',
                     slots_attributes: [
                       {
                         start_at: availability[:start_at],
                         end_at: (DateTime.parse(availability[:start_at]) + 1.hour).to_s(:iso8601),
                         availability_id: availability[:id]
                       }
                     ]
                   }
                 }
               ]
             }
           }.to_json, headers: default_headers
    end

    assert_equal 422, response.status
    assert_match /slot is restricted for subscribers/, response.body

    assert_equal reservations_count, Reservation.count
    assert_equal invoices_count, Invoice.count
    assert_equal slots_count, Slot.count
  end

  test 'admin force reservation of a slot restricted to subscribers' do
    login_as(@admin, scope: :user)

    reservations_count = Reservation.count
    availabilities_count = Availability.count
    invoices_count = Invoice.count
    slots_count = Slot.count

    # first, create the restricted availability
    date = 4.days.from_now.utc.change(hour: 8, min: 0, sec: 0)
    post '/api/availabilities',
         params: {
           availability: {
             start_at: date.iso8601,
             end_at: (date + 6.hours).iso8601,
             available_type: 'machines',
             slot_duration: 60,
             machine_ids: [2],
             occurrences: [
               { start_at: date.iso8601, end_at: (date + 6.hours).iso8601 }
             ],
             plan_ids: [2]
           }
         }

    assert_equal 201, response.status

    # Check the id
    availability = json_response(response.body)
    assert_not_nil availability[:id], 'availability ID was unexpectedly nil'

    assert_equal availabilities_count + 1, Availability.count

    # book a reservation
    VCR.use_cassette('reservations_create_for_restricted_slot_fails') do
      post '/api/local_payment/confirm_payment',
           params: {
             customer_id: @jdupont.id,
             items: [
               {
                 reservation: {
                   reservable_id: 2,
                   reservable_type: 'Machine',
                   slots_attributes: [
                     {
                       start_at: availability[:start_at],
                       end_at: (DateTime.parse(availability[:start_at]) + 1.hour).to_s(:iso8601),
                       availability_id: availability[:id]
                     }
                   ]
                 }
               }
             ]
           }.to_json, headers: default_headers
    end

    assert_equal 201, response.status

    # Check the result
    result = json_response(response.body)
    assert_not_nil result[:id], 'invoice ID was unexpectedly nil'

    assert_equal reservations_count + 1, Reservation.count
    assert_equal invoices_count + 1, Invoice.count
    assert_equal slots_count + 1, Slot.count
  end

  test 'book a slot restricted to subscribers and a subscription at the same time' do
    login_as(@admin, scope: :user)

    reservations_count = Reservation.count
    availabilities_count = Availability.count
    invoices_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    slots_count = Slot.count
    subscriptions_count = Subscription.count

    # first, create the restricted availability
    date = 4.days.from_now.utc.change(hour: 8, min: 0, sec: 0)
    post '/api/availabilities',
         params: {
           availability: {
             start_at: date.iso8601,
             end_at: (date + 6.hours).iso8601,
             available_type: 'machines',
             slot_duration: 60,
             machine_ids: [2],
             occurrences: [
               { start_at: date.iso8601, end_at: (date + 6.hours).iso8601 }
             ],
             plan_ids: [2]
           }
         }

    assert_equal 201, response.status

    # Check the id
    availability = json_response(response.body)
    assert_not_nil availability[:id], 'availability ID was unexpectedly nil'

    assert_equal availabilities_count + 1, Availability.count

    # change connected user
    login_as(@jdupont, scope: :user)

    # book a reservation
    VCR.use_cassette('reservations_create_for_restricted_slot_fails') do
      post '/api/stripe/confirm_payment',
           params: {
             payment_method_id: stripe_payment_method,
             cart_items: {
               items: [
                 {
                   reservation: {
                     reservable_id: 2,
                     reservable_type: 'Machine',
                     slots_attributes: [
                       {
                         start_at: availability[:start_at],
                         end_at: (DateTime.parse(availability[:start_at]) + 1.hour).to_s(:iso8601),
                         availability_id: availability[:id]
                       }
                     ]
                   }
                 },
                 {
                   subscription: {
                     plan_id: 2
                   }
                 }
               ]
             }
           }.to_json, headers: default_headers
    end

    assert_equal 201, response.status

    # Check the result
    result = json_response(response.body)
    assert_not_nil result[:id], 'invoice ID was unexpectedly nil'

    assert_equal reservations_count + 1, Reservation.count
    assert_equal invoices_count + 1, Invoice.count
    assert_equal slots_count + 1, Slot.count
    assert_equal subscriptions_count + 1, Subscription.count
    assert_equal invoice_items_count + 2, InvoiceItem.count
  end
end
