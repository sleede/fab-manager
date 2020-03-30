# frozen_string_literal: true

# SpaceFile is a file stored on the file system, associated with a Space.
class SpaceFile < Asset
  mount_uploader :attachment, SpaceFileUploader
end
