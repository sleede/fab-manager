# frozen_string_literal: true

# Check the access policies for API::ProductCategoriesController
class ProductCategoryPolicy < ApplicationPolicy
  def create?
    user.admin?
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin?
  end
end
