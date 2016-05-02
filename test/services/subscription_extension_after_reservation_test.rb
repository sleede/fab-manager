require 'test_helper'

class SubscriptionExtensionAfterReservationTest < ActiveSupport::TestCase
  setup do
    @machine = Machine.find(6)
    @training = Training.find(2)

    @plan = Plan.find(3)
    @plan.update!(is_rolling: true)

    @user = User.joins(:subscriptions).find_by(subscriptions: { plan: @plan })

    @user.reservations.destroy_all # ensure no reservations

    @availability = @machine.availabilities.first
    slot = Slot.new(start_at: @availability.start_at, end_at: @availability.end_at, availability_id: @availability.id)
    @reservation_machine = Reservation.new(user: @user, reservable: @machine, slots: [slot])
    @reservation_training = Reservation.new(user: @user, reservable: @training, slots: [slot])
    @reservation_training.save!
  end

  test "is eligible for extension because all conditions are met by default (test setup)" do
    assert SubscriptionExtensionAfterReservation.new(@reservation_training).eligible_to_extension?
  end

  test "not eligible if reservable is a machine" do
    @reservation_machine.save!
    refute SubscriptionExtensionAfterReservation.new(@reservation_machine).eligible_to_extension?
  end

  test "not eligible if user doesn't have subscription" do
    @user.subscriptions.destroy_all
    refute SubscriptionExtensionAfterReservation.new(@reservation_training).eligible_to_extension?
  end

  test "not eligible if subscription is expired" do
    @user.subscription.update!(expired_at: 10.years.ago)
    refute SubscriptionExtensionAfterReservation.new(@reservation_training).eligible_to_extension?
  end

  test "not eligible if plan attribute 'is_rolling' is false/nil" do
    @plan.update!(is_rolling: false)
    refute SubscriptionExtensionAfterReservation.new(@reservation_training).eligible_to_extension?
  end

  test "method extend_subscription" do
    SubscriptionExtensionAfterReservation.new(@reservation_training).extend_subscription
    assert_equal @reservation_training.slots.first.start_at + @plan.duration, @user.subscription.expired_at
  end
end
