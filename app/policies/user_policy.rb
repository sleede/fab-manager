# frozen_string_literal: true

# Check the access policies for API::MembersController and API::UsersController
class UserPolicy < ApplicationPolicy
  # Defines the scope of the users index, depending on the role of the current user
  class Scope < Scope
    def resolve
      if user.admin?
        scope.includes(:group, :training_credits, :machine_credits, statistic_profile: [subscriptions: [plan: [:credits]]], profile: [:user_avatar])
             .joins(:roles).where("users.is_active = 'true' AND roles.name = 'member'").order('users.created_at desc')
      else
        scope.includes(profile: [:user_avatar]).joins(:roles).where("users.is_active = 'true' AND roles.name = 'member'")
             .where(is_allow_contact: true).order('users.created_at desc')
      end
    end
  end

  def show?
    user.admin? || user.manager? || (record.is_allow_contact && record.member?) || (user.id == record.id)
  end

  def update?
    user.admin? || user.manager? || (user.id == record.id)
  end

  def destroy?
    user.admin? || (user.id == record.id)
  end

  %w[merge complete_tour].each do |action|
    define_method "#{action}?" do
      user.id == record.id
    end
  end

  %w[list index].each do |action|
    define_method "#{action}?" do
      user.admin? || user.manager?
    end
  end

  %w[create mapping].each do |action|
    define_method "#{action}?" do
      user.admin?
    end
  end
end
