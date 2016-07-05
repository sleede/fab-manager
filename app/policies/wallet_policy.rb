class WalletPolicy < ApplicationPolicy
  def by_user?
    user.is_admin?
  end

  def transactions?
    user.is_admin? or user == record.user
  end
end
