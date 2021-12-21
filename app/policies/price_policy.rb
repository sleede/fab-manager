# frozen_string_literal: true

# Check the access policies for API::PricesController
class PricePolicy < ApplicationPolicy
  def create?
    user.admin? && record.duration != 60
  end

  def update?
    user.admin?
  end
end
