import { FileType } from './file';
import { AdvancedAccounting } from './advanced-accounting';
import { TDateISO } from '../typings/date-iso';

export interface Space {
  id: number,
  name: string,
  description: string,
  characteristics?: string,
  slug: string,
  default_places: number,
  disabled: boolean,
  space_image_attributes?: FileType,
  space_file_attributes?: Array<FileType>,
  advanced_accounting_attributes?: AdvancedAccounting,
  created_at?: TDateISO,
  updated_at?: TDateISO
}
