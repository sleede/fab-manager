class AuthProviderPolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      scope.includes(:providable)
    end
  end

  %w(index? show? create? update? destroy? mapping_fields?).each do |action|
    define_method action do
      user.is_admin?
    end
  end

  def active?
    user
  end

  def send_code?
    user
  end
end
