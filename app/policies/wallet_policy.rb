class WalletPolicy < ApplicationPolicy
  def by_user?
    user.is_admin?
  end
end
