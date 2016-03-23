class CreditPolicy < ApplicationPolicy
  def index?
    user.is_admin?
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
