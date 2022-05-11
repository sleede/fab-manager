import { TDateISO } from '../typings/date-iso';

export interface ReservationSlot {
  id?: number,
  start_at: TDateISO,
  end_at: TDateISO,
  availability_id: number,
  offered: boolean
}

export interface Reservation {
  reservable_id: number,
  reservable_type: string,
  slots_attributes: Array<ReservationSlot>,
  nb_reserve_places?: number,
  tickets_attributes?: {
    event_price_category_id: number,
    booked: boolean,
  },
}
