class PricePolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def update?
    user.admin?
  end
end
