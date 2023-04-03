# frozen_string_literal: true

require 'test_helper'

class SubscriptionExtensionAfterReservationTest < ActiveSupport::TestCase
  setup do
    @machine = Machine.find(6)
    @training = Training.find(2)

    @plan = Plan.find(3)
    @plan.update!(is_rolling: true)

    @user = User.joins(statistic_profile: [:subscriptions]).find_by(subscriptions: { plan_id: @plan.id })

    @user.reservations.destroy_all # ensure no reservations

    @slot_reservation_machine = SlotsReservation.new({ slot_id: @machine.availabilities.first.slots.first.id })
    @slot_reservation_training = SlotsReservation.new({ slot_id: @training.availabilities.first.slots.first.id })

    @reservation_machine = Reservation.new(
      statistic_profile: @user.statistic_profile,
      reservable: @machine,
      slots_reservations: [@slot_reservation_machine]
    )
    @reservation_training = Reservation.new(
      statistic_profile: @user.statistic_profile,
      reservable: @training,
      slots_reservations: [@slot_reservation_training]
    )
    @reservation_training.save!
  end

  test 'is eligible for extension because all conditions are met by default (test setup)' do
    assert Subscriptions::ExtensionAfterReservation.new(@reservation_training).eligible_to_extension?
  end

  test 'not eligible if reservable is a machine' do
    @reservation_machine.save!
    assert_not Subscriptions::ExtensionAfterReservation.new(@reservation_machine).eligible_to_extension?
  end

  test "not eligible if user doesn't have subscription" do
    user = users(:user2) # no subscriptions
    reservation_training = Reservation.new(
      statistic_profile: user.statistic_profile,
      reservable: @training,
      slots_reservations: [@slot_reservation_training]
    )
    assert_not Subscriptions::ExtensionAfterReservation.new(reservation_training).eligible_to_extension?
  end

  test 'not eligible if subscription is expired' do
    @user.subscription.update!(expiration_date: 10.years.ago)
    assert_not Subscriptions::ExtensionAfterReservation.new(@reservation_training).eligible_to_extension?
  end

  test "not eligible if plan attribute 'is_rolling' is false/nil" do
    @plan.update!(is_rolling: false)
    assert_not Subscriptions::ExtensionAfterReservation.new(@reservation_training).eligible_to_extension?
  end

  test 'method extend_subscription' do
    Subscriptions::ExtensionAfterReservation.new(@reservation_training).extend_subscription
    assert_equal @reservation_training.slots_reservations.first.slot.start_at + @plan.duration, @user.subscription.expired_at
  end
end
