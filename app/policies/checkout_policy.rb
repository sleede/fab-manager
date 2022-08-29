# frozen_string_literal: true

# Check the access policies for API::CheckoutController
class CheckoutPolicy < ApplicationPolicy
  %w[payment confirm_payment].each do |action|
    define_method "#{action}?" do
      return user.privileged? || (record.statistic_profile_id == user.statistic_profile.id)
    end
  end
end
