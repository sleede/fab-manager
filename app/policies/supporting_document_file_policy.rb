# frozen_string_literal: true

# Check the access policies for API::SupportingDocumentFilesController
class SupportingDocumentFilePolicy < ApplicationPolicy
  def index?
    user.privileged?
  end

  %w[create update download].each do |action|
    define_method "#{action}?" do
      user.privileged? ||
        (record.supportable_type == 'User' && record.supportable_id.to_i == user.id) ||
        (record.supportable_type == 'Child' && user.children.exists?(id: record.supportable_id.to_i))
    end
  end
end
