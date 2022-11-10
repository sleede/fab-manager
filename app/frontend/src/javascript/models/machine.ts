import { Reservation } from './reservation';
import { ApiFilter } from './api';
import { FileType } from './file';
import { AdvancedAccounting } from './advanced-accounting';

export interface MachineIndexFilter extends ApiFilter {
  disabled: boolean,
}

export interface Machine {
  id?: number,
  name: string,
  description?: string,
  spec?: string,
  disabled: boolean,
  slug: string,
  machine_image_attributes: FileType,
  machine_files_attributes?: Array<FileType>,
  trainings?: Array<{
    id: number,
    name: string,
    disabled: boolean,
  }>,
  current_user_is_trained?: boolean,
  current_user_next_training_reservation?: Reservation,
  current_user_has_packs?: boolean,
  has_prepaid_packs_for_current_user?: boolean,
  machine_projects?: Array<{
    id: number,
    name: string,
    slug: string,
  }>,
  advanced_accounting_attributes?: AdvancedAccounting
}
