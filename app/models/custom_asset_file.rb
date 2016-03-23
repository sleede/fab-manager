class CustomAssetFile < Asset
  mount_uploader :attachment, CustomAssetsUploader
end
