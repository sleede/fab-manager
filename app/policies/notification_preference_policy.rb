# frozen_string_literal: true

# Check the access policies for API::NotificationPreferencesController
class NotificationPreferencePolicy < ApplicationPolicy
  def update?
    user.admin? || user.manager?
  end

  def bulk_update?
    user.admin? || user.manager?
  end
end
