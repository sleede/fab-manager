# frozen_string_literal: true

require 'test_helper'

class TrainingServiceTest < ActiveSupport::TestCase
  setup do
    @training = Training.find(4)
    @availability = Availability.find(22)
  end

  test 'auto cancel reservation with less reservations than the deadline' do
    @training.update(auto_cancel: true, auto_cancel_threshold: 3, auto_cancel_deadline: 24)
    customer = User.find(3)
    slot = @availability.slots.first
    r = Reservation.create!(
      reservable_id: @training.id,
      reservable_type: Training.name,
      slots_reservations_attributes: [{ slot_id: slot.id }],
      statistic_profile_id: StatisticProfile.find_by(user: customer).id
    )
    TrainingService.auto_cancel_reservation(@training)
    r.reload
    assert_not_nil r.slots_reservations.first&.canceled_at
  end

  test 'do not auto cancel reservation with more reservations than the deadline' do
    @training.update(auto_cancel: true, auto_cancel_threshold: 3, auto_cancel_deadline: 24)
    slot = @availability.slots.first

    # first reservation
    c1 = User.find(2)
    r1 = Reservation.create!(
      reservable_id: @training.id,
      reservable_type: Training.name,
      slots_reservations_attributes: [{ slot_id: slot.id }],
      statistic_profile_id: StatisticProfile.find_by(user: c1).id
    )

    # second reservation
    c2 = User.find(3)
    r2 = Reservation.create!(
      reservable_id: @training.id,
      reservable_type: Training.name,
      slots_reservations_attributes: [{ slot_id: slot.id }],
      statistic_profile_id: StatisticProfile.find_by(user: c2).id
    )

    # third reservation
    c3 = User.find(3)
    r3 = Reservation.create!(
      reservable_id: @training.id,
      reservable_type: Training.name,
      slots_reservations_attributes: [{ slot_id: slot.id }],
      statistic_profile_id: StatisticProfile.find_by(user: c3).id
    )

    TrainingService.auto_cancel_reservation(@training)
    r1.reload
    assert_nil r1.slots_reservations.first&.canceled_at
    r2.reload
    assert_nil r2.slots_reservations.first&.canceled_at
    r3.reload
    assert_nil r3.slots_reservations.first&.canceled_at
  end
end
