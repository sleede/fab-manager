# frozen_string_literal: true

# Check the access policies for API::SlotsReservationsController
class SlotsReservationPolicy < ApplicationPolicy
  def update?
    # check that the update is allowed and the prevention delay has not expired
    delay = Setting.get('booking_move_delay').to_i
    enabled = Setting.get('booking_move_enable')

    # these condition does not apply to admins
    user.admin? || user.manager? ||
      (record.reservation.user == user && enabled && ((record.slot.start_at - Time.current).to_i / 3600 >= delay))
  end

  def cancel?
    return false unless user
    return false if record.canceled_at.present?
    return true if user.privileged?

    return false unless record.reservation&.user == user
    return false unless Setting.get('booking_cancel_enable') == true

    start_at = record.slot&.start_at
    return false unless start_at

    raw_delay = Setting.get('booking_cancel_delay')
    return false if raw_delay.nil? || raw_delay.to_s.strip !~ /\A\d+\z/

    now = Time.current
    delay = raw_delay.to_i

    start_at > now && start_at >= now + delay.hours
  end

  def validate?
    user.admin? || user.manager?
  end

  def invalidate?
    user.admin? || user.manager?
  end
end
