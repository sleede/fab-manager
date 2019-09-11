# frozen_string_literal: true

# Check the access policies for API::ReservationsController
class ReservationPolicy < ApplicationPolicy
  def create?
    user.admin? || record.price.zero?
  end

  def update?
    user.admin? || record.user == user
  end
end
