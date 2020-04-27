# frozen_string_literal: true

# Check the access policies for API::ReservationsController
class ReservationPolicy < ApplicationPolicy
  def create?
    user.admin? || (user.manager? && record.user_id != user.id) || record.price.zero?
  end

  def update?
    user.admin? || user.manager? || record.user == user
  end
end
