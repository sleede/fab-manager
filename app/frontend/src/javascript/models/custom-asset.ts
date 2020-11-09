export interface CustomAsset {
  id: number,
  name: string,
  custom_asset_file_attributes: {
    id: number,
    attachment: string
    attachment_url: string
  }
}
