# frozen_string_literal: true

# Check the access policies for API::SubscriptionsController
class SubscriptionPolicy < ApplicationPolicy
  def show?
    user.admin? || user.manager? || record.user.id == user.id
  end

  def payment_details?
    user.admin? || user.manager?
  end

  def cancel?
    user.admin? || user.manager?
  end
end
