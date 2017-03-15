class ProjectStepImage < Asset
  include ImageValidatorConcern
  mount_uploader :attachment, ProjectImageUploader
end
