# frozen_string_literal: true

# Services around subscriptions
module Subscriptions; end

# Extend the user's current subscription after his first training reservation if
# he subscribed to a rolling plan
class Subscriptions::ExtensionAfterReservation
  attr_accessor :user, :reservation

  def initialize(reservation)
    @user = reservation.user
    @reservation = reservation
  end

  def extend_subscription_if_eligible
    extend_subscription if eligible_to_extension?
  end

  def eligible_to_extension?
    return false unless reservation.reservable_type == 'Training'
    return false if user.reservations.where(reservable_type: 'Training').count != 1
    return false unless user.subscription
    return false if user.subscription.expired?
    return false unless user.subscribed_plan.is_rolling

    true
  end

  def extend_subscription
    user.subscription.update_columns( # rubocop:disable Rails/SkipsModelValidations
      expiration_date: reservation.slots_reservations.first.slot.start_at + user.subscribed_plan.duration
    )
  end
end
