export interface ReservationSlot {
  start_at: Date,
  end_at: Date,
  availability_id: number,
  offered: boolean
}

export interface Reservation {
  user_id: number,
  reservable_id: number,
  reservable_type: string,
  slots_attributes: Array<ReservationSlot>,
  plan_id: number
  payment_schedule: boolean
}
