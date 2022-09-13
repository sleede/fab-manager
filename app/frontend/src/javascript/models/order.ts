import { TDateISO } from '../typings/date-iso';
import { PaymentConfirmation } from './payment';
import { CreateTokenResponse } from './payzen';
import { UserRole } from './user';
import { Coupon } from './coupon';

export interface Order {
  id: number,
  token: string,
  statistic_profile_id?: number,
  user?: {
    id: number,
    role: UserRole
    name?: string,
  },
  operator_profile_id?: number,
  reference?: string,
  state?: string,
  payment_state?: string,
  total?: number,
  coupon?: Coupon,
  created_at?: TDateISO,
  updated_at?: TDateISO,
  invoice_id?: number,
  payment_method?: string,
  payment_date?: TDateISO,
  wallet_amount?: number,
  paid_total?: number,
  order_items_attributes: Array<{
    id: number,
    orderable_type: string,
    orderable_id: number,
    orderable_name: string,
    orderable_main_image_url?: string,
    quantity: number,
    quantity_min: number,
    amount: number,
    is_offered: boolean
  }>,
}

export interface OrderPayment {
  order: Order,
  payment?: PaymentConfirmation|CreateTokenResponse
}

export interface OrderIndex {
  page: number,
  total_pages: number,
  page_size: number,
  total_count: number,
  data: Array<Order>
}

export interface OrderIndexFilter {
  user_id?: number,
  page?: number,
  sort?: 'DESC'|'ASC'
}
