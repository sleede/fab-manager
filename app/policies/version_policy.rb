class VersionPolicy < ApplicationPolicy
  def show?
    user.is_admin?
  end
end
