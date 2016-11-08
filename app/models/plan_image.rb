class PlanImage < Asset
  include ImageValidatorConcern
  mount_uploader :attachment, PlanImageUploader
end
