# frozen_string_literal: true

# Check the access policies for API::ProductsController
class ProductPolicy < ApplicationPolicy
  def create?
    user.privileged?
  end

  def update?
    user.privileged?
  end

  def destroy?
    user.privileged?
  end

  def stock_movements?
    user.privileged?
  end
end
