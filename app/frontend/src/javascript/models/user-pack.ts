import { TDateISO } from '../typings/date-iso';
import { ApiFilter } from './api';

export interface UserPackIndexFilter extends ApiFilter {
  user_id: number,
  priceable_type?: string,
  priceable_id?: number,
  history?: boolean
}

export interface UserPack {
  id: number,
  minutes_used: number,
  expires_at: TDateISO,
  prepaid_pack: {
    minutes: number,
    priceable_type: 'Machine'|'Space',
    priceable: {
      name: string
    }
  },
  history?: Array<{
    id: number,
    consumed_minutes: number,
    reservation_id: number,
    reservation_date: TDateISO
  }>
}
