# frozen_string_literal: true

# Check the access policies for API::InvoicesController
class InvoicePolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def download?
    user.admin? || user.manager? || (record.invoicing_profile.user_id == user.id)
  end

  def create?
    user.admin? || user.manager?
  end

  def list?
    user.admin? || user.manager?
  end

  def first?
    user.admin?
  end
end
