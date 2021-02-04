# frozen_string_literal: true

# Check the access policies for API::PaymentSchedulesController
class PaymentSchedulePolicy < ApplicationPolicy
  def list?
    user.admin? || user.manager?
  end

  def cash_check?
    user.admin? || user.manager?
  end

  def download?
    user.admin? || user.manager? || (record.invoicing_profile.user_id == user.id)
  end
end
