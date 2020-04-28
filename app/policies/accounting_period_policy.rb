# frozen_string_literal: true

# Check the access policies for API::AccountingPeriodsController
class AccountingPeriodPolicy < ApplicationPolicy
  %w[index show create download_archive].each do |action|
    define_method "#{action}?" do
      user.admin?
    end
  end

  def last_closing_end?
    user.admin? || user.manager?
  end
end
