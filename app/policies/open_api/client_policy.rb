# frozen_string_literal: true

# Check the access policies for OpenAPI::ClientsController
class OpenAPI::ClientPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  # Admin can view all tokens
  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(user_id: user.id)
      end
    end
  end

  def create?
    user.present?
  end

  def update?
    user.admin? or record.user_id == user.id
  end

  def reset_token?
    user.admin? | record.user_id == user.id
  end

  def destroy?
    user.admin? || record.user_id == user.id
  end
end
