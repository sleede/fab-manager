# frozen_string_literal: true

# Check the access policies for API::WalletController
class WalletPolicy < ApplicationPolicy
  def by_user?
    user.admin? || user.manager? || user == record.user
  end

  def transactions?
    user.admin? || user == record.user
  end

  def credit?
    user.admin?
  end
end
