class ReservationPolicy < ApplicationPolicy
  def update?
    user.admin? or record.user == user
  end
end
