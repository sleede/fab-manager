class CreditPolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def create?
    index?
  end

  def update?
    index?
  end

  def destroy?
    index?
  end
end
