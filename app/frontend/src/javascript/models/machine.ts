import { Reservation } from './reservation';

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
  machine_projects?: Array<{
    id: number,
    name: string,
    slug: string,
  }>
}
