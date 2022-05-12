class ProofOfIdentityFilePolicy < ApplicationPolicy

  def index?
    user.privileged?
  end

  def create?
    user.privileged? or record.user_id == user.id
  end

  def update?
    user.privileged? or record.user_id == user.id
  end

  def download?
    user.privileged? or record.user_id == user.id
  end
end
