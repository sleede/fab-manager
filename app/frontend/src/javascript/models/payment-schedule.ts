export enum PaymentScheduleItemState {
  New = 'new',
  Pending = 'pending',
  RequirePaymentMethod = 'requires_payment_method',
  RequireAction = 'requires_action',
  Paid = 'paid',
  Error = 'error'
}

export enum PaymentMethod {
  Stripe = 'stripe',
  Check = 'check'
}
export interface PaymentScheduleItem {
  id: number,
  amount: number,
  due_date: Date,
  state: PaymentScheduleItemState,
  invoice_id: number,
  payment_method: PaymentMethod,
  client_secret?: string,
  details: {
    recurring: number,
    adjustment?: number,
    other_items?: number,
    without_coupon?: number,
    subscription_id: number
  }
}

export interface PaymentSchedule {
  max_length: number;
  id: number,
  scheduled_type: string,
  scheduled_id: number,
  total: number,
  stp_subscription_id: string,
  reference: string,
  payment_method: string,
  wallet_amount: number,
  items: Array<PaymentScheduleItem>,
  created_at: Date,
  chained_footprint: boolean,
  user: {
    name: string
  },
  operator: {
    id: number,
    first_name: string,
    last_name: string,
  }
}

export interface PaymentScheduleIndexRequest {
  query: {
    reference?: string,
    customer?: string,
    date?: Date,
    page: number,
    size: number
  }
}

export interface CashCheckResponse {
  state: PaymentScheduleItemState,
  payment_method: PaymentMethod
}
