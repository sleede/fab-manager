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
    user.admin? || user.manager? || record.reservation.user == user
  end

  def validate?
    user.admin? || user.manager?
  end

  def invalidate?
    user.admin? || user.manager?
  end
end
