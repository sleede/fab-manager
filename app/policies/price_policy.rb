# frozen_string_literal: true

# Check the access policies for API::PricesController
class PricePolicy < ApplicationPolicy
  def update?
    user.admin?
  end
end
