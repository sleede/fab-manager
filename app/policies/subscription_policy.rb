class SubscriptionPolicy < ApplicationPolicy
  def show?
    user.admin? or record.user_id == user.id
  end

  def update?
    user.admin?
  end
end
