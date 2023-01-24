import { ApiFilter } from './api';
import { TDateISO } from '../typings/date-iso';
import { FileType } from './file';
import { AdvancedAccounting } from './advanced-accounting';

export interface Training {
  id?: number,
  name: string,
  description: string,
  machine_ids: number[],
  nb_total_places: number,
  slug?: string,
  public_page?: boolean,
  disabled?: boolean,
  plan_ids?: number[],
  training_image_attributes?: FileType,
  auto_cancel: boolean,
  auto_cancel_threshold: number,
  auto_cancel_deadline: number,
  availabilities?: Array<{
    id: number,
    start_at: TDateISO,
    end_at: TDateISO,
    reservation_users: Array<{
      id: number,
      full_name: string,
      is_valid: boolean
    }>
  }>,
  advanced_accounting_attributes?: AdvancedAccounting
}

export interface TrainingIndexFilter extends ApiFilter {
  disabled?: boolean,
  public_page?: boolean,
  requested_attributes?: ['availabillities'],
}
