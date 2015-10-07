class UserPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.is_admin?
        scope.with_role(:member).includes(:group, :profile => [:user_avatar]).order('created_at desc')
      else
        scope.with_role(:member).includes(:group, :profile => [:user_avatar]).where(is_allow_contact: true).order('created_at desc')
      end
    end
  end

  def show?
    user.is_admin? or (record.is_allow_contact and record.has_role?(:member)) or (user.id == record.id)
  end

  def create?
    user.is_admin?
  end

  def update?
    user.is_admin? or (user.id == record.id)
  end
end
