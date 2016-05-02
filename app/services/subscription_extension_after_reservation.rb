class SubscriptionExtensionAfterReservation
  attr_accessor :user, :reservation

  def initialize(reservation)
    @user, @reservation = reservation.user, reservation
  end

  def extend_subscription_if_eligible
    extend_subscription if eligible_to_extension?
  end

  def eligible_to_extension?
    return false unless reservation.reservable_type == 'Training'
    return false if user.reservations.where(reservable_type: 'Training').count != 1
    return false unless user.subscription
    return false if user.subscription.is_expired?
    return false unless user.subscribed_plan.is_rolling
    return true
  end

  def extend_subscription
    user.subscription.update_columns(
      expired_at: reservation.slots.first.start_at + user.subscribed_plan.duration
    )
  end
end
