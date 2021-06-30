# frozen_string_literal: true

# Check the access policies for API::GroupsController
class GroupPolicy < ApplicationPolicy
  def create?
    user.admin?
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin? && record.destroyable?
  end
end
