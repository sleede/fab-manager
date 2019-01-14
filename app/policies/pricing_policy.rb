class PricingPolicy < ApplicationPolicy
  def update?
    user.admin?
  end
end
