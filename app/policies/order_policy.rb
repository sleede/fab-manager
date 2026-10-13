# frozen_string_literal: true

# Check the access policies for API::OrdersController
class OrderPolicy < ApplicationPolicy
  def show?
    user_owns_order?
  end

  def update?
    user.privileged?
  end

  def destroy?
    user.privileged?
  end

  def withdrawal_instructions?
    record&.cart? || user_owns_order?
  end

  private

  def user_owns_order?
    return false unless user
    return true if user.privileged?

    profile_id = user.statistic_profile&.id
    profile_id.present? && record&.statistic_profile_id == profile_id
  end
end
