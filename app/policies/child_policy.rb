# frozen_string_literal: true

# Check the access policies for API::ChildrenController
class ChildPolicy < ApplicationPolicy
  # Defines the scope of the children index, depending on the current user
  class Scope < Scope
    def resolve
      scope.where(user_id: user.id)
    end
  end

  def index?
    !user.organization?
  end

  def create?
    !user.organization? && user.id == record.user_id
  end

  def show?
    user.id == record.user_id
  end

  def update?
    user.id == record.user_id
  end

  def destroy?
    user.id == record.user_id
  end
end
