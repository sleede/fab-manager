# frozen_string_literal: true

# Check if user is an admin to allow create, update and destroy project_category
class ProjectCategoryPolicy < ApplicationPolicy
  def create?
    user.admin?
  end

  def update?
    create?
  end

  def destroy?
    create?
  end
end
