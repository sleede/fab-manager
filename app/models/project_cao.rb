# frozen_string_literal: true

# CAD file attached to a project documentation
class ProjectCao < Asset
  mount_uploader :attachment, ProjectCaoUploader

  validates :attachment, file_size: { maximum: Rails.application.secrets.max_cao_size&.to_i || 5.megabytes.to_i }
end
