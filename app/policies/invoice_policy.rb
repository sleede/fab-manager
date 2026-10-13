# frozen_string_literal: true

# Check the access policies for API::InvoicesController
class InvoicePolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def show?
    download?
  end

  def download?
    return false unless user
    return true if user.admin? || user.manager?

    profile_user_id = record.invoicing_profile&.user_id
    profile_user_id.present? && profile_user_id == user.id
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
