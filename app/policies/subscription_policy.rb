class SubscriptionPolicy < ApplicationPolicy
  def show?
    user.is_admin? or record.user_id == user.id
  end

  def update?
    user.is_admin?
  end
end
