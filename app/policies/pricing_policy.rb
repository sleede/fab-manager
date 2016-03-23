class PricingPolicy < ApplicationPolicy
  def update?
    user.is_admin?
  end
end
