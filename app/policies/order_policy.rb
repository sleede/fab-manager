# frozen_string_literal: true

# Check the access policies for API::OrdersController
class OrderPolicy < ApplicationPolicy
  def show?
    user.privileged? || (record.statistic_profile_id == user.statistic_profile.id)
  end

  def update?
    user.privileged?
  end

  def destroy?
    user.privileged?
  end

  def withdrawal_instructions?
    user&.privileged? || (record&.statistic_profile_id == user&.statistic_profile&.id)
  end
end
