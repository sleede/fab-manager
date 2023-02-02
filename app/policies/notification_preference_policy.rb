# frozen_string_literal: true

# Check the access policies for API::NotificationController
class NotificationPreferencePolicy < ApplicationPolicy
  def update?
    user.admin?
  end

  def bulk_update?
    user.admin?
  end
end
