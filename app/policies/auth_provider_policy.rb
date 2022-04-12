# frozen_string_literal: true

# Check the access policies for API::AuthProvidersController
class AuthProviderPolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      scope.includes(:providable)
    end
  end

  %w[index? show? create? update? destroy? mapping_fields? strategy_name?].each do |action|
    define_method action do
      user.admin?
    end
  end

  def active?
    user
  end

  def send_code?
    user
  end
end
