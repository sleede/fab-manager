json.custom_asset do
  if @custom_asset
    json.extract! @custom_asset, :id, :name
    json.custom_asset_file_attributes do
      json.id @custom_asset.custom_asset_file.id
      json.attachment @custom_asset.custom_asset_file.attachment_identifier
      json.attachment_url @custom_asset.custom_asset_file.attachment_url
    end if @custom_asset.custom_asset_file
  else
    json.nil!
  end
end