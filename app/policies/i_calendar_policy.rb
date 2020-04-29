# frozen_string_literal: true

# Check the access policies for API::ICalendarController
class ICalendarPolicy < ApplicationPolicy
  def create?
    user.admin? || user.manager?
  end

  def destroy?
    user.admin? || user.manager?
  end
end
