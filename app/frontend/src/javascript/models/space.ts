import { FileType } from './file';
import { AdvancedAccounting } from './advanced-accounting';

export interface Space {
  id: number,
  name: string,
  description: string,
  slug: string,
  default_places: number,
  disabled: boolean,
  space_image_attributes: FileType,
  space_file_attributes?: Array<FileType>,
  advanced_accounting_attributes?: AdvancedAccounting
}
