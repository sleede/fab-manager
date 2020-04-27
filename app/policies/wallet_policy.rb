# frozen_string_literal: true

# Check the access policies for API::WalletController
class WalletPolicy < ApplicationPolicy
  %w[by_user transactions].each do |action|
    define_method "#{action}?" do
      user.admin? || user.manager? || user == record.user
    end
  end

  def credit?
    user.admin?
  end
end
