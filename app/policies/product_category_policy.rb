# frozen_string_literal: true

# Check the access policies for API::ProductCategoriesController
class ProductCategoryPolicy < ApplicationPolicy
  def create?
    user.privileged?
  end

  def update?
    user.privileged?
  end

  def destroy?
    user.privileged?
  end

  def position?
    user.privileged?
  end
end
