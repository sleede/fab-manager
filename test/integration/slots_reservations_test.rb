# frozen_string_literal: true

require 'test_helper'

class SlotsReservationsTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    @user = User.members.without_subscription.first
    login_as(@admin, scope: :user)
  end

  test 'cancel a reservation' do
    put '/api/slots_reservations/1/cancel'

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the reservation was correctly canceled
    slots_reservation = SlotsReservation.find(1)
    assert_not_nil slots_reservation
    assert_not_nil slots_reservation.canceled_at

    # place cache
    slot = slots_reservation.slot
    slot.reload
    cached = slot.places.detect do |p|
      p['reservable_id'] == slots_reservation.reservation.reservable_id && p['reservable_type'] == slots_reservation.reservation.reservable_type
    end
    assert_not_nil cached
    assert_equal 0, cached['reserved_places']
    assert_not_includes cached['user_ids'], slots_reservation.reservation.statistic_profile.user_id
  end

  test 'update a reservation' do
    machine = Machine.find(6)
    availability = machine.availabilities.first
    slot = availability.slots.first

    post '/api/local_payment/confirm_payment', params: {
      customer_id: @user.id,
      items: [
        {
          reservation: {
            reservable_id: machine.id,
            reservable_type: machine.class.name,
            slots_reservations_attributes: [
              {
                slot_id: slot.id
              }
            ]
          }
        }
      ]
    }.to_json, headers: default_headers

    # general assertions about creation
    assert_equal 201, response.status
    slots_reservation = SlotsReservation.last
    assert_equal slot.id, slots_reservation.slot_id

    # place cache
    slot.reload
    cached = slot.places.detect { |p| p['reservable_id'] == machine.id && p['reservable_type'] == machine.class.name }
    assert_not_nil cached
    assert_equal 1, cached['reserved_places']
    assert_includes cached['user_ids'], @user.id

    # update the reservation to another slot
    new_slot = availability.slots.last

    patch "/api/slots_reservations/#{slots_reservation.id}",
          params: {
            slots_reservation: {
              slot_id: new_slot.id
            }
          }

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the reservation was correctly moved
    slots_reservation.reload
    assert_equal new_slot.id, slots_reservation.slot_id

    # old place cache
    slot.reload
    cached = slot.places.detect do |p|
      p['reservable_id'] == machine.id && p['reservable_type'] == machine.class.name
    end
    assert_not_nil cached
    assert_equal 0, cached['reserved_places']
    assert_not_includes cached['user_ids'], @user.id
    # new cache place
    new_slot.reload
    cached = new_slot.places.detect do |p|
      p['reservable_id'] == slots_reservation.reservation.reservable_id && p['reservable_type'] == slots_reservation.reservation.reservable_type
    end
    assert_not_nil cached
    assert_equal 1, cached['reserved_places']
    assert_includes cached['user_ids'], @user.id
  end
end
