class WalletPolicy < ApplicationPolicy
  def by_user?
    user.is_admin? or user == record.user
  end

  def transactions?
    user.is_admin? or user == record.user
  end

  def credit?
    user.is_admin?
  end
end
