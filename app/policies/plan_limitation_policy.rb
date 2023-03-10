# frozen_string_literal: true

# Check the access policies for API::PlanLimitationsController
class PlanLimitationPolicy < ApplicationPolicy
  def destroy?
    user.admin?
  end
end
