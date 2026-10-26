# frozen_string_literal: true

require 'test_helper'

class CancelAuthorizationTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  setup do
    Warden.test_reset!
    @admin = users(:user1)
    @manager = users(:user5)
    @manager.add_role :manager unless @manager.manager?

    @member = users(:user2)
    @other_member = users(:user3)
    @machine = Machine.find(1)
    @availability = @machine.availabilities.first

    Setting.set('booking_cancel_enable', true)
    Setting.set('booking_cancel_delay', 24)
  end

  teardown do
    Warden.test_reset!
    travel_back
    Setting.set('booking_cancel_enable', false)
    Setting.set('booking_cancel_delay', 24)
  end

  test 'member cannot cancel reservation when booking_cancel_enable is false' do
    Setting.set('booking_cancel_enable', false)
    base_time = Time.zone.parse('2026-10-24 12:00:00')

    travel_to base_time do
      sr = build_slot_reservation(@member, base_time + 48.hours)
      login_as(@member, scope: :user)

      put "/api/slots_reservations/#{sr.id}/cancel"

      assert_response :forbidden
      assert_nil sr.reload.canceled_at
    end
  end

  test 'member cannot cancel reservation when booking_cancel_enable is missing' do
    Setting.set('booking_cancel_enable', nil)
    base_time = Time.zone.parse('2026-10-24 12:00:00')

    travel_to base_time do
      sr = build_slot_reservation(@member, base_time + 48.hours)
      login_as(@member, scope: :user)

      put "/api/slots_reservations/#{sr.id}/cancel"

      assert_response :forbidden
      assert_nil sr.reload.canceled_at
    end
  end

  test 'member cannot cancel when booking_cancel_delay is missing or invalid' do
    base_time = Time.zone.parse('2026-10-24 12:00:00')

    [nil, '', 'abc', -5].each do |invalid_delay|
      Setting.set('booking_cancel_delay', invalid_delay)

      travel_to base_time do
        sr = build_slot_reservation(@member, base_time + 48.hours)
        login_as(@member, scope: :user)

        put "/api/slots_reservations/#{sr.id}/cancel"

        assert_response :forbidden
        assert_nil sr.reload.canceled_at
      end
    end
  end

  test 'member cannot cancel reservation in the past' do
    base_time = Time.zone.parse('2026-10-24 12:00:00')

    travel_to base_time do
      sr = build_slot_reservation(@member, base_time - 1.hour)
      login_as(@member, scope: :user)

      put "/api/slots_reservations/#{sr.id}/cancel"

      assert_response :forbidden
      assert_nil sr.reload.canceled_at
    end
  end

  test 'member cannot cancel reservation after delay deadline has passed' do
    base_time = Time.zone.parse('2026-10-24 12:00:00')

    travel_to base_time do
      sr = build_slot_reservation(@member, base_time + 23.hours)
      login_as(@member, scope: :user)

      put "/api/slots_reservations/#{sr.id}/cancel"

      assert_response :forbidden
      assert_nil sr.reload.canceled_at
    end
  end

  test 'member can cancel reservation exactly at the deadline' do
    base_time = Time.zone.parse('2026-10-24 12:00:00')

    travel_to base_time do
      sr = build_slot_reservation(@member, base_time + 24.hours)
      login_as(@member, scope: :user)

      put "/api/slots_reservations/#{sr.id}/cancel"

      assert_response :ok
      assert_not_nil sr.reload.canceled_at
    end
  end

  test 'member can cancel reservation well before deadline' do
    base_time = Time.zone.parse('2026-10-24 12:00:00')

    travel_to base_time do
      sr = build_slot_reservation(@member, base_time + 48.hours)
      login_as(@member, scope: :user)

      put "/api/slots_reservations/#{sr.id}/cancel"

      assert_response :ok
      assert_not_nil sr.reload.canceled_at
    end
  end

  test 'member cannot cancel reservation of another user' do
    base_time = Time.zone.parse('2026-10-24 12:00:00')

    travel_to base_time do
      sr = build_slot_reservation(@member, base_time + 48.hours)
      login_as(@other_member, scope: :user)

      put "/api/slots_reservations/#{sr.id}/cancel"

      assert_response :forbidden
      assert_nil sr.reload.canceled_at
    end
  end

  test 'cannot cancel an already canceled reservation repeatedly' do
    base_time = Time.zone.parse('2026-10-24 12:00:00')
    initial_cancel_time = base_time - 2.hours

    travel_to base_time do
      sr = build_slot_reservation(@member, base_time + 48.hours)
      sr.update_columns(canceled_at: initial_cancel_time) # rubocop:disable Rails/SkipsModelValidations

      login_as(@member, scope: :user)
      put "/api/slots_reservations/#{sr.id}/cancel"
      assert_response :forbidden

      login_as(@admin, scope: :user)
      put "/api/slots_reservations/#{sr.id}/cancel"
      assert_response :forbidden

      assert_equal initial_cancel_time.to_i, sr.reload.canceled_at.to_i
    end
  end

  test 'admin can cancel reservation when setting is false and deadline has passed' do
    Setting.set('booking_cancel_enable', false)
    base_time = Time.zone.parse('2026-10-24 12:00:00')

    travel_to base_time do
      sr = build_slot_reservation(@member, base_time + 2.hours)
      login_as(@admin, scope: :user)

      put "/api/slots_reservations/#{sr.id}/cancel"

      assert_response :ok
      assert_not_nil sr.reload.canceled_at
    end
  end

  test 'manager can cancel reservation when setting is false and deadline has passed' do
    Setting.set('booking_cancel_enable', false)
    base_time = Time.zone.parse('2026-10-24 12:00:00')

    travel_to base_time do
      sr = build_slot_reservation(@member, base_time + 2.hours)
      login_as(@manager, scope: :user)

      put "/api/slots_reservations/#{sr.id}/cancel"

      assert_response :ok
      assert_not_nil sr.reload.canceled_at
    end
  end

  test 'service lock guarantees idempotency under repeated calls' do
    base_time = Time.zone.parse('2026-10-24 12:00:00')

    travel_to base_time do
      sr1 = build_slot_reservation(@member, base_time + 48.hours)
      sr2 = SlotsReservation.find(sr1.id)

      first_call = SlotsReservationsService.cancel(sr1)
      second_call = SlotsReservationsService.cancel(sr2)

      assert_equal true, first_call
      assert_equal false, second_call
    end
  end

  test 'cancellation persists in DB even if elasticsearch connection fails' do
    base_time = Time.zone.parse('2026-10-24 12:00:00')

    travel_to base_time do
      sr = build_slot_reservation(@member, base_time + 48.hours)

      client = Elasticsearch::Model.client
      original_method = client.method(:delete_by_query)
      client.define_singleton_method(:delete_by_query) do |*_args|
        raise Faraday::ConnectionFailed, 'ES connection failed'
      end

      begin
        result = SlotsReservationsService.cancel(sr)
        assert_equal true, result
      ensure
        client.define_singleton_method(:delete_by_query, original_method)
      end

      assert_not_nil sr.reload.canceled_at
      fresh_sr = SlotsReservation.find(sr.id)
      assert_equal false, SlotsReservationsService.cancel(fresh_sr)
    end
  end

  private

  def build_slot_reservation(user, start_at)
    slot = Slot.create!(
      availability: @availability,
      start_at: start_at,
      end_at: start_at + 1.hour,
      places: [{ 'user_ids' => [user.id], 'reservable_id' => @machine.id, 'reservable_type' => 'Machine', 'reserved_places' => 1 }]
    )
    res = Reservation.create!(
      statistic_profile: user.statistic_profile,
      reservable: @machine,
      reservation_context_id: 1
    )
    SlotsReservation.create!(
      slot: slot,
      reservation: res
    )
  end
end
