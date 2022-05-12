import { TDateISO } from '../typings/date-iso';

export interface PriceIndexFilter {
  priceable_type?: string,
  priceable_id?: number,
  group_id?: number,
  plan_id?: number|null,
}

export interface Price {
  id: number,
  group_id: number,
  plan_id: number,
  priceable_type: string,
  priceable_id: number,
  amount: number,
  duration?: number // in minutes
}

export interface ComputePriceResult {
  price: number,
  price_without_coupon: number,
  details?: {
    slots: Array<{
      start_at: TDateISO,
      price: number,
      promo: boolean
    }>
    plan?: number
  },
  schedule?: {
    items: Array<{
      amount: number,
      due_date: TDateISO
    }>
  }
}
