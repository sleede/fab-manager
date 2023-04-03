import { TDateISODate } from '../typings/date-iso';
import { ApiFilter } from './api';

export interface ChildIndexFilter extends ApiFilter {
  user_id: number,
}

export interface Child {
  id?: number,
  last_name: string,
  first_name: string,
  email?: string,
  phone?: string,
  birthday: TDateISODate,
  user_id: number
}
