# frozen_string_literal: true

# Check the access policies for API::AccountingPeriodsController
class AccountingPeriodPolicy < ApplicationPolicy
  %w[index show create last_closing_end].each do |action|
    define_method "#{action}?" do
      user.admin?
    end
  end
end
