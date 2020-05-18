# frozen_string_literal: true

# Check the access policies for API::TrainingsController
class TrainingPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.includes(:plans, :machines)
    end
  end

  def create?
    user.admin?
  end

  def update?
    user.admin? || user.manager?
  end

  def destroy?
    user.admin? && record.destroyable?
  end

  def availabilities?
    user.admin? || user.manager?
  end
end
