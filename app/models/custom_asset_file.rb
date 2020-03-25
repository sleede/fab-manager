# frozen_string_literal: true

# CustomAssetFile is a file stored on the file system, associated with a CustomAsset.
class CustomAssetFile < Asset
  mount_uploader :attachment, CustomAssetsUploader
end
