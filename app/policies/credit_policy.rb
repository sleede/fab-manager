# frozen_string_literal: true

# Check the access policies for API::CreditsController
class CreditPolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def create?
    index?
  end

  def update?
    index?
  end

  def destroy?
    index?
  end

  def user_resource?
    record.id == user.id || user.admin?
  end
end
