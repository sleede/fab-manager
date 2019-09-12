class InvoicePolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def download?
    user.admin? or (record.invoicing_profile.user_id == user.id)
  end

  def create?
    user.admin?
  end

  def list?
    user.admin?
  end
end
