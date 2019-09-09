class ReservationPolicy < ApplicationPolicy
  def create?
    user.admin?
  end

  def update?
    user.admin? or record.user == user
  end
end
