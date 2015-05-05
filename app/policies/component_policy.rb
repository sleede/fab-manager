class ComponentPolicy < ApplicationPolicy
  def create?
    user.is_admin?
  end

  def update?
    create?
  end

  def destroy?
    create?
  end
end
