# frozen_string_literal: true

# Main image for project documentation
class ProjectImage < Asset
  include ImageValidatorConcern
  mount_uploader :attachment, ProjectImageUploader
end
