# frozen_string_literal: true

# Check the access policies for API::ChildrenController
class ChildPolicy < ApplicationPolicy
  def create?
    !user.organization? && user.id == record.user_id
  end

  def show?
    user.privileged? || user.id == record.user_id
  end

  def update?
    user.privileged? || user.id == record.user_id
  end

  def destroy?
    user.privileged? || user.id == record.user_id
  end

  def validate?
    user.privileged?
  end
end
