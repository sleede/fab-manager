# frozen_string_literal: true

# Check the access policies for API::AvailabilitiesController
class AvailabilityPolicy < ApplicationPolicy
  %w[index? show? create? update? destroy? reservations? export? lock?].each do |action|
    define_method action do
      user.admin? || user.manager?
    end
  end
end
