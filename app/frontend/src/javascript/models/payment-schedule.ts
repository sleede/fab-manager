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
  client_secret?: string
}

export interface PaymentSchedule {
  max_length: number;
  id: number,
  total: number,
  reference: string,
  payment_method: string,
  items: Array<PaymentScheduleItem>,
  created_at: Date,
  chained_footprint: boolean,
  main_object: {
    type: string,
    id: number
  },
  user: {
    id: number,
    name: string
  },
  operator: {
    id: number,
    first_name: string,
    last_name: string,
  },
  gateway_subscription: {
    classname: string
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

export interface RefreshItemResponse {
  state: 'refreshed'
}

export interface PayItemResponse {
  status: 'draft' | 'open' | 'paid' | 'uncollectible' | 'void',
  error?: string
}

export interface CancelScheduleResponse {
  canceled_at: Date
}
