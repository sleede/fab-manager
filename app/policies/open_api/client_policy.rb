class OpenAPI::ClientPolicy < ApplicationPolicy
  def index?
    user.has_role? :admin
  end

  def create?
    user.has_role? :admin
  end

  def update?
    user.has_role? :admin
  end

  def reset_token?
    user.has_role? :admin
  end

  def destroy?
    user.has_role? :admin and record.calls_count == 0
  end
end
