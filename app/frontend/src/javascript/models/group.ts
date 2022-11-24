import { ApiFilter } from './api';

export interface GroupIndexFilter extends ApiFilter {
  disabled?: boolean
}

export interface Group {
  id: number,
  slug: string,
  name: string,
  disabled: boolean,
  users?: number
}
