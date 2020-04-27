class AdminPolicy < ApplicationPolicy
  def index?
    user.admin? || user.manager?
  end

  def create?
    user.admin?
  end
end
