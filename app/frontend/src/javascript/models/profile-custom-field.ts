import { ApiFilter } from './api';

export interface ProfileCustomField {
  id: number,
  label: string,
  required: boolean,
  actived: boolean
}

export interface ProfileCustomFieldIndexFilters extends ApiFilter {
  actived?: boolean
}
