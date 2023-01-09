# frozen_string_literal: true

# Check the access policies for API::AdminsController
class AdminPolicy < ApplicationPolicy
  def index?
    user.admin? || user.manager?
  end

  def create?
    user.admin?
  end
end
