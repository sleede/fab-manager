
export interface Space {
  id: number,
  name: string,
  description: string,
  slug: string,
  default_places: number,
  disabled: boolean,
  space_image: string,
  space_file_attributes?: {
    id: number,
    attachment: string,
    attachement_url: string,
  }
}
