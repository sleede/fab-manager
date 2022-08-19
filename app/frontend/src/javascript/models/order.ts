import { TDateISO } from '../typings/date-iso';

export interface Order {
  id: number,
  token: string,
  statistic_profile_id?: number,
  operator_id?: number,
  reference?: string,
  state?: string,
  amount?: number,
  created_at?: TDateISO,
  order_items_attributes: Array<{
    id: number,
    orderable_type: string,
    orderable_id: number,
    orderable_name: string,
    quantity: number,
    amount: number,
    is_offered: boolean
  }>,
}
