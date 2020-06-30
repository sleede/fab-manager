# frozen_string_literal: true

# Images for the documentation of a ProjectStep
class ProjectStepImage < Asset
  include ImageValidatorConcern
  mount_uploader :attachment, ProjectImageUploader
end
