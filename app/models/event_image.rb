# frozen_string_literal: true

# EventImage is the main picture for an Events.
class EventImage < Asset
  include ImageValidatorConcern
  mount_uploader :attachment, EventImageUploader
end
