import { Reservation } from './reservation';

export interface MachineIndexFilter {
  disabled: boolean,
}

export interface Machine {
  id: number,
  name: string,
  description?: string,
  spec?: string,
  disabled: boolean,
  slug: string,
  machine_image: string,
  machine_files_attributes?: Array<{
    id: number,
    attachment: string,
    attachment_url: string
  }>,
  trainings?: Array<{
    id: number,
    name: string,
    disabled: boolean,
  }>,
  current_user_is_trained?: boolean,
  current_user_next_training_reservation?: Reservation,
  current_user_has_packs?: boolean,
  current_user_available_for_packs_renewal?: boolean,
  has_prepaid_packs_for_current_user?: boolean,
  machine_projects?: Array<{
    id: number,
    name: string,
    slug: string,
  }>
}
