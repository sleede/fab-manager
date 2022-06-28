import { TDateISO } from '../typings/date-iso';
import { ApiFilter } from './api';

export type ReservableType = 'Training' | 'Event' | 'Space' | 'Machine';

export interface ReservationSlot {
  id?: number,
  start_at: TDateISO,
  end_at: TDateISO,
  canceled_at?: TDateISO,
  availability_id?: number,
  offered?: boolean,
  is_reserved?: boolean
}

export interface Reservation {
  id?: number,
  user_id?: number,
  user_full_name?: string,
  message?: string,
  reservable_id: number,
  reservable_type: ReservableType,
  slots_attributes: Array<ReservationSlot>,
  nb_reserve_places?: number,
  tickets_attributes?: {
    event_price_category_id: number,
    booked: boolean,
  },
  total_booked_seats?: number,
  created_at?: TDateISO,
}

export interface ReservationIndexFilter extends ApiFilter {
  reservable_id?: number,
  reservable_type?: ReservableType | Array<ReservableType>,
  user_id?: number
}
