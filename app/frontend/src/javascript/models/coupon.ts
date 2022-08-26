export interface Coupon {
  id: number,
  code: string,
  type: string,
  amount_off: number,
  percent_off: number,
  validity_per_user: string
}
