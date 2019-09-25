# frozen_string_literal: true

# Check the access policies for API::ImportsController
class ImportPolicy < ApplicationPolicy
  def show?
    user.admin?
  end

  def members?
    user.admin?
  end
end
