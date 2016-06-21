class UserPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.is_admin?
        scope.includes(:group, :training_credits, :machine_credits, :subscriptions => [:plan => [:credits]], :profile => [:user_avatar]).joins(:roles).where("users.is_active = 'true' AND roles.name = 'member'").order('users.created_at desc')
      else
        scope.includes(:profile => [:user_avatar]).joins(:roles).where("users.is_active = 'true' AND roles.name = 'member'").where(is_allow_contact: true).order('users.created_at desc')
      end
    end
  end

  def show?
    user.is_admin? or (record.is_allow_contact and record.is_member?) or (user.id == record.id)
  end

  def update?
    user.is_admin? or (user.id == record.id)
  end

  def destroy?
    user.id == record.id
  end

  def merge?
    user.id == record.id
  end

  %w(list create mapping).each do |action|
    define_method "#{action}?" do
      user.is_admin?
    end
  end
end
