import { TDateISO } from '../typings/date-iso';
import { PaymentConfirmation } from './payment';
import { CreateTokenResponse } from './payzen';
import { User } from './user';

export interface Order {
  id: number,
  token: string,
  statistic_profile_id?: number,
  user?: User,
  operator_id?: number,
  reference?: string,
  state?: string,
  total?: number,
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

export interface OrderPayment {
  order: Order,
  payment?: PaymentConfirmation|CreateTokenResponse
}
