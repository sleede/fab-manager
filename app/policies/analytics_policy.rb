# frozen_string_literal: true

# Check the access policies for API::AnalyticsController
class AnalyticsPolicy < ApplicationPolicy
  def data?
    user.admin?
  end
end
