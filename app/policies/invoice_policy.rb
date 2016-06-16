class InvoicePolicy < ApplicationPolicy
  def index?
    user.is_admin?
  end

  def download?
    user.is_admin? or (record.user_id == user.id)
  end

  def create?
    user.is_admin?
  end

  def list?
    user.is_admin?
  end
end
