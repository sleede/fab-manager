# frozen_string_literal: true

# Check the access policies for API::ReservationsController
class ReservationPolicy < ApplicationPolicy
  def create?
    user.admin? || (user.manager? && record.user_id != user.id) || record.price.zero?
  end

  def show?
    return false unless user
    return true if user.admin? || user.manager?

    profile_id = user.statistic_profile&.id
    profile_id.present? && record.statistic_profile_id == profile_id
  end

  def update?
    user.admin? || user.manager? || record.user == user
  end

  def confirm_payment?
    user.admin? || user.manager?
  end
end
