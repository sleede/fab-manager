class TrainingPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.includes(:plans, :machines, :availabilities => [:slots => [:reservation => [:user => [:profile, :trainings]]]]).order('availabilities.start_at DESC')
    end
  end

  def create?
    user.is_admin?
  end

  def update?
    user.is_admin?
  end

  def destroy?
    user.is_admin? and record.destroyable?
  end
end
