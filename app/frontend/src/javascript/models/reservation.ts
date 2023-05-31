import { TDateISO } from '../typings/date-iso';
import { ApiFilter } from './api';

export type ReservableType = 'Training' | 'Event' | 'Space' | 'Machine';

export interface SlotsReservation {
  id?: number,
  canceled_at?: TDateISO,
  offered?: boolean,
  slot_id?: number,
  slot_attributes?: {
    id: number,
    start_at: TDateISO,
    end_at: TDateISO,
    availability_id: number
  }
}
// TODO, refactor Reservation for cart_items (in payment) => should use slot_id instead of (start_at + end_at)

export interface Reservation {
  id?: number,
  user_id?: number,
  user_full_name?: string,
  message?: string,
  reservable_id: number,
  reservable_type: ReservableType,
  slots_reservations_attributes: Array<SlotsReservation>,
  reservable?: {
    id: number,
    name: string
  },
  nb_reserve_places?: number,
  tickets_attributes?: {
    event_price_category_id: number,
    event_price_category?: {
      id: number,
      price_category_id: number,
      price_category: {
        id: number,
        name: string
      }
    },
    booked: boolean,
    created_at?: TDateISO
  },
  total_booked_seats?: number,
  created_at?: TDateISO,
  booking_users_attributes?: {
    id: number,
    name: string,
    event_price_category_id: number,
    booked_id: number,
    booked_type: string,
  }
}

export interface ReservationIndexFilter extends ApiFilter {
  reservable_id?: number,
  reservable_type?: ReservableType | Array<ReservableType>,
  user_id?: number
}
