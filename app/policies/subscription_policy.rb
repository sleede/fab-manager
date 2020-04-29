# frozen_string_literal: true

# Check the access policies for API::SubscriptionsController
class SubscriptionPolicy < ApplicationPolicy
  include FablabConfiguration
  def create?
    !fablab_plans_deactivated? && (user.admin? || (user.manager? && record.user_id != user.id) || record.price.zero?)
  end

  def show?
    user.admin? or record.user_id == user.id
  end

  def update?
    user.admin?
  end
end
