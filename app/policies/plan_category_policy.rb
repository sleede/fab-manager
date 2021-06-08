# frozen_string_literal: true

# Check the access policies for API::PlanCategoriesController
class PlanCategoryPolicy < ApplicationPolicy
  %w[index show create update destroy].each do |action|
    define_method "#{action}?" do
      user.admin?
    end
  end
end
