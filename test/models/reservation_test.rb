# frozen_string_literal: true

require 'test_helper'

class ReservationTest < ActiveSupport::TestCase
  setup do
    @machine_reservation = reservations(:reservation_2) # Machine reservation with slot 2
    @machine = @machine_reservation.reservable
    @statistic_profile = statistic_profiles(:admin)
  end

  # BUG-02: Updating an existing machine reservation should not conflict with itself
  test 'BUG-02: updating attributes of existing machine reservation does not trigger self-conflict already reserved error' do
    assert @machine_reservation.persisted?
    assert @machine_reservation.reservable.is_a?(Machine)
    assert @machine_reservation.slots_reservations.any?

    # Before fix, any update on an existing machine reservation failed with "already reserved"
    assert @machine_reservation.update(message: 'Updated reservation message note')
    assert_empty @machine_reservation.errors[:reservable]
    assert_equal 'Updated reservation message note', @machine_reservation.reload.message
  end

  test 'BUG-02: another reservation on the same machine and slot is correctly rejected as already reserved' do
    existing_slot_id = @machine_reservation.slots_reservations.first.slot_id

    # Create another reservation attempting to book the same machine slot
    conflicting_reservation = Reservation.new(
      reservable: @machine,
      statistic_profile: @statistic_profile,
      message: 'Conflicting booking'
    )
    conflicting_reservation.slots_reservations.build(slot_id: existing_slot_id)

    refute conflicting_reservation.valid?, 'Expected conflicting reservation on same slot to be invalid'
    assert_includes conflicting_reservation.errors[:reservable], 'already reserved'
  end

  test 'BUG-02: canceled reservation slot does not block new reservation on the same slot' do
    # Cancel the existing slot reservation
    slot_res = @machine_reservation.slots_reservations.first
    slot_res.update!(canceled_at: Time.current)

    new_reservation = Reservation.new(
      reservable: @machine,
      statistic_profile: @statistic_profile,
      message: 'Booking on canceled slot'
    )
    new_reservation.slots_reservations.build(slot_id: slot_res.slot_id)

    # When slot is canceled, machine_not_already_reserved should not add 'already reserved'
    new_reservation.valid?
    refute_includes new_reservation.errors[:reservable], 'already reserved'
  end
end

class ReservationsIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @machine_reservation = reservations(:reservation_2)
    @user = @machine_reservation.user
  end

  test 'BUG-02: API PATCH /api/reservations/:id successfully updates an existing machine reservation' do
    login_as(@user, scope: :user)

    patch "/api/reservations/#{@machine_reservation.id}",
          params: {
            reservation: { message: 'Updated via API' }
          }.to_json,
          headers: default_headers

    assert_response :success
    assert_equal 'Updated via API', @machine_reservation.reload.message
  end
end
