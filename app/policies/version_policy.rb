class VersionPolicy < ApplicationPolicy
  def show?
    user.admin?
  end
end
