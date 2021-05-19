# frozen_string_literal: true

# Check the access policies for API::LocalPaymentsController
class LocalPaymentPolicy < ApplicationPolicy
  def confirm_payment?
    user.admin? || (user.manager? && record.shopping_cart.customer.id != user.id) || record.price.zero?
  end
end
