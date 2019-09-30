# frozen_string_literal: true

# Check the access policies for API::CouponsController
class CouponPolicy < ApplicationPolicy
  %w[index show create update destroy send_to].each do |action|
    define_method "#{action}?" do
      user.admin?
    end
  end
end
