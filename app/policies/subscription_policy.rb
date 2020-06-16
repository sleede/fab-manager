# frozen_string_literal: true

# Check the access policies for API::SubscriptionsController
class SubscriptionPolicy < ApplicationPolicy
  def create?
    Setting.get('plans_module') && (user.admin? || (user.manager? && record.user_id != user.id) || record.price.zero?)
  end

  def show?
    user.admin? or record.user_id == user.id
  end

  def update?
    user.admin? || (user.manager? && record.user.id != user.id)
  end
end
