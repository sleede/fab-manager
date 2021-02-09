# frozen_string_literal: true

# Check the access policies for API::PaymentSchedulesController
class PaymentSchedulePolicy < ApplicationPolicy
  %w[list? cash_check?].each do |action|
    define_method action do
      user.admin? || user.manager?
    end
  end

  %w[refresh_item? download? pay_item?].each do |action|
    define_method action do
      user.admin? || user.manager? || (record.invoicing_profile.user_id == user.id)
    end
  end
end
