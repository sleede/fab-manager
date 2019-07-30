# frozen_string_literal: true

# Check the access policies for API::AccountingExportsController
class AccountingExportsPolicy < ApplicationPolicy
  def export?
    user.admin?
  end
end
