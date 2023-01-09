# frozen_string_literal: true

# Check the access policies for API::AgeRangesController
class AgeRangePolicy < ApplicationPolicy
  %w[create update destroy show].each do |action|
    define_method "#{action}?" do
      user.admin?
    end
  end
end
