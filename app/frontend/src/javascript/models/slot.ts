import { TDateISO } from '../typings/date-iso';

export interface Slot {
  slot_id: number,
  can_modify: boolean,
  title: string,
  start: TDateISO,
  end: TDateISO,
  is_reserved: boolean,
  is_completed: boolean,
  backgroundColor: 'white',

  availability_id: number,
  slots_reservations_ids: Array<number>,
  tag_ids: Array<number>,
  tags: Array<{
    id: number,
    name: string,
  }>
  plan_ids: Array<number>,

  // the users who booked on this slot, if any
  users: Array<{
    id: number,
    name: string
  }>,

  borderColor?: '#eeeeee' | '#b2e774' | '#e4cd78' | '#bd7ae9' | '#dd7e6b' | '#3fc7ff' | '#000',
  // machine
  machine?: {
    id: number,
    name: string
  },
  // training
  nb_total_places?: number,
  training?: {
    id: number,
    name: string,
    description: string,
    machines: Array<{
      id: number,
      name: string
    }>
  },
  // space
  space?: {
    id: number,
    name: string
  }
}
