class ProjectImage < Asset
  include ImageValidatorConcern
  mount_uploader :attachment, ProjectImageUploader
end
