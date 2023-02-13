# frozen_string_literal: true

# Check the access policies for API::SupportingDocumentFilesController
class SupportingDocumentFilePolicy < ApplicationPolicy
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
