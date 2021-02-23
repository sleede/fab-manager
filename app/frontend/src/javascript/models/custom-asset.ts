export enum CustomAssetName {
  LogoFile = 'logo-file',
  LogoBlackFile = 'logo-black-file',
  CguFile = 'cgu-file',
  CgvFile = 'cgv-file',
  ProfileImageFile = 'profile-image-file',
  FaviconFile = 'favicon-file'
}

export interface CustomAsset {
  id: number,
  name: CustomAssetName,
  custom_asset_file_attributes: {
    id: number,
    attachment: string
    attachment_url: string
  }
}
