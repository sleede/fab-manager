# frozen_string_literal: true

# Check the access policies for API::AccountingExportsController
class AccountingExportPolicy < ApplicationPolicy
  def export?
    user.admin?
  end
end
