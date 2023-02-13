# frozen_string_literal: true

# Check the access policies for API::SupportingDocumentTypesController
class SupportingDocumentTypePolicy < ApplicationPolicy
  def create?
    user.admin?
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin?
  end
end
