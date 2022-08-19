# frozen_string_literal: true

# Check the access policies for API::CartController
class CartPolicy < ApplicationPolicy
  def create?
    true
  end

  %w[add_item remove_item set_quantity].each do |action|
    define_method "#{action}?" do
      user.privileged? || (record.statistic_profile.user_id == user.id)
    end
  end
end
