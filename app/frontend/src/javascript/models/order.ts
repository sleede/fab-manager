import { TDateISO } from '../typings/date-iso';
import { PaymentConfirmation } from './payment';
import { CreateTokenResponse } from './payzen';
import { UserRole } from './user';
import { Coupon } from './coupon';
import { ApiFilter, PaginatedIndex } from './api';

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
    orderable_ref?: string,
    orderable_main_image_url?: string,
    orderable_external_stock: number,
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

export type OrderIndex = PaginatedIndex<Order>;

export type OrderSortOption = 'created_at-asc' | 'created_at-desc' | '';

export interface OrderIndexFilter extends ApiFilter {
  reference?: string,
  user_id?: number,
  user?: {
    id: number,
    name?: string,
  },
  page?: number,
  sort?: OrderSortOption
  states?: Array<string>,
  period_from?: string,
  period_to?: string
}
