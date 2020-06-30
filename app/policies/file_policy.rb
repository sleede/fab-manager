# frozen_string_literal: true

# Check the access policies for API::FilesController
class FilePolicy < ApplicationPolicy
  def mime?
    user.admin?
  end
end
