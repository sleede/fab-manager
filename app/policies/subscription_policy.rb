# frozen_string_literal: true

# Check the access policies for API::SubscriptionsController
class SubscriptionPolicy < ApplicationPolicy
  def show?
    user.admin? or record.user_id == user.id
  end

  def payment_details?
    user.admin? || user.manager?
  end
end
