class EventImage < Asset
  include ImageValidatorConcern
  mount_uploader :attachment, EventImageUploader
end
