class TrainingPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.includes(:plans, :machines)
    end
  end

  %w(create update).each do |action|
    define_method "#{action}?" do
      user.is_admin?
    end
  end

  def destroy?
    user.is_admin? and record.destroyable?
  end

  def availabilities?
    user.is_admin?
  end
end
