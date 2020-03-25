# frozen_string_literal: true

# Images for the documentation of a ProjectStep
class ProjectStepImage < Asset
  include ImageValidatorConcern
  mount_uploader :attachment, ProjectImageUploader

  validates :attachment, file_mime_type: { content_type: /image/ }
end
