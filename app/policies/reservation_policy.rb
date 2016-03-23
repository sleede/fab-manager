class ReservationPolicy < ApplicationPolicy
  def update?
    user.is_admin? or record.user == user
  end
end
