# frozen_string_literal: true

# Check the access policies for API::SettingsController
class SettingPolicy < ApplicationPolicy
  %w[update bulk_update reset].each do |action|
    define_method "#{action}?" do
      user.admin?
    end
  end
end
