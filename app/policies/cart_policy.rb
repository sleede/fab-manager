# frozen_string_literal: true

# Check the access policies for API::CartController
class CartPolicy < ApplicationPolicy
  def create?
    !Setting.get('store_hidden') || user&.privileged?
  end

  %w[add_item remove_item set_quantity refresh_item validate].each do |action|
    define_method "#{action}?" do
      return user.privileged? || (record.statistic_profile_id == user.statistic_profile.id) if user

      record.statistic_profile_id.nil? && record.operator_profile_id.nil?
    end
  end

  def set_offer?
    !record.is_offered || (user.privileged? && record.customer_id != user.id)
  end
end
