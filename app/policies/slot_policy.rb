class SlotPolicy < ApplicationPolicy
  def update?
    # check that the update is allowed and the prevention delay has not expired
    delay = Setting.find_by( name: 'booking_move_delay').value.to_i
    enabled = (Setting.find_by( name: 'booking_move_enable').value == 'true')

    # these condition does not apply to admins
    user.is_admin? or
        (record.reservation.user == user and enabled and ((record.start_at - Time.now).to_i / 3600 >= delay))
  end

  def cancel?
    user.is_admin? or record.reservation.user == user
  end
end
