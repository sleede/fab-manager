# frozen_string_literal: true

# SpaceImage is the main picture for a Space
class SpaceImage < Asset
  mount_uploader :attachment, SpaceImageUploader
end