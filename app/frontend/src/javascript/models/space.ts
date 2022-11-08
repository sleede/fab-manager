import { FileType } from './file';

export interface Space {
  id: number,
  name: string,
  description: string,
  slug: string,
  default_places: number,
  disabled: boolean,
  space_image_attributes: FileType,
  space_file_attributes?: Array<FileType>
}
