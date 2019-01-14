class CustomAssetPolicy < ApplicationPolicy

  def create?
    user.admin?
  end

  def update?
    user.admin?
  end

end
