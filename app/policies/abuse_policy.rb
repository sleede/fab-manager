# frozen_string_literal: true

# Check the access policies for API::AbusesController
class AbusePolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def destroy?
    user.admin?
  end
end
