class WalletPolicy < ApplicationPolicy
  def by_user?
    user.admin? or user == record.user
  end

  def transactions?
    user.admin? or user == record.user
  end

  def credit?
    user.admin?
  end
end
