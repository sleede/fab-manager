# frozen_string_literal: true

# Check the access policies for API::PaymentsController
class PaymentPolicy < ApplicationPolicy
  def online_payment_status?
    user.admin?
  end
end
