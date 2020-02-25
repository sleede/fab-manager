# frozen_string_literal: true

# Main image for project documentation
class ProjectImage < Asset
  include ImageValidatorConcern
  mount_uploader :attachment, ProjectImageUploader

  validates :attachment, file_mime_type: { content_type: /image/ }
end
