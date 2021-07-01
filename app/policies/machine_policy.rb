# frozen_string_literal: true

# Check the access policies for API::MachinesController
class MachinePolicy < ApplicationPolicy
  def create?
    user.admin?
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin? and record.destroyable?
  end
end
