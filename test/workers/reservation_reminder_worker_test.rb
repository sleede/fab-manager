# frozen_string_literal: true

require 'test_helper'
require 'minitest/autorun'

class ReservationReminderWorkerTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @worker = ReservationReminderWorker.new

    @training_slot = slots(:slot_1)

    @event = events(:event_1)
    @event_slot = slots(:slot_129)
    @event_reservation = Reservation.create!(
      reservable: @event,
      nb_reserve_places: 1,
      statistic_profile_id: statistic_profiles(:pdurand).id,
      slots_reservations_attributes: [slot_id: @event_slot.id]
    )
  end

  test 'send a reminder 24 hours before by default and is idempotent' do
    travel_to @training_slot.start_at - 24.hours

    assert_enqueued_emails 1 do
      @worker.perform
    end

    assert_enqueued_emails 0 do
      @worker.perform
    end
  end

  test 'reminder_delay can be changed and is respected' do
    Setting.set('reminder_delay', 15)

    travel_to @training_slot.start_at - 17.hours

    assert_enqueued_emails 0 do
      @worker.perform
    end

    travel_to @training_slot.start_at - 13.hours

    assert_enqueued_emails 0 do
      @worker.perform
    end

    travel_to @training_slot.start_at - 15.hours

    assert_enqueued_emails 1 do
      @worker.perform
    end

    assert_enqueued_emails 0 do
      @worker.perform
    end
  end

  test 'do nothing if setting reminder_enable is false' do
    Setting.set('reminder_enable', false)

    assert_enqueued_emails 0 do
      assert_nil @worker.perform
    end
  end

  test 'do nothing if slots_reservations is canceled' do
    travel_to @training_slot.start_at - 24.hours

    @training_slot.slots_reservations[0].update!(canceled_at: 1.day.ago)

    assert_enqueued_emails 0 do
      @worker.perform
    end
  end

  test '[event] do nothing if event.pre_registration is true and slots_reservation is not valid' do
    @event.update!(pre_registration: true)
    @event_reservation.slots_reservations.update_all(is_valid: false)

    travel_to @event_slot.start_at - 24.hours

    assert_enqueued_emails 0 do
      @worker.perform
    end
  end

  test '[event] do send the notification if event.pre_registration is true and slots_reservation is valid' do
    @event.update!(pre_registration: true)
    @event_reservation.slots_reservations.update_all(is_valid: true)

    travel_to @event_slot.start_at - 24.hours

    assert_enqueued_emails 1 do
      @worker.perform
    end
  end

  test '[event] do send the notification if event.pre_registration is false' do
    travel_to @event_slot.start_at - 24.hours

    assert_enqueued_emails 1 do
      @worker.perform
    end
  end
end
