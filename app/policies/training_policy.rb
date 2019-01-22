class TrainingPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.includes(:plans, :machines)
    end
  end

  %w(create update).each do |action|
    define_method "#{action}?" do
      user.admin?
    end
  end

  def destroy?
    user.admin? and record.destroyable?
  end

  def availabilities?
    user.admin?
  end
end
