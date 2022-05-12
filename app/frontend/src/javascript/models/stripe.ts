import { PaymentIntent } from '@stripe/stripe-js';

// https://stripe.com/docs/api/tokens/object
export interface PIIToken {
  id: string,
  object: 'token',
  client_ip: string,
  created: number,
  livemode: boolean,
  type: 'pii',
  used: boolean
}

// https://stripe.com/docs/api/charges/object
export interface Charge {
  id: string,
  object: 'charge',
  amount: number,
  amount_captured: number,
  amount_refunded: number,
  application?: string,
  application_fee?: string,
  application_fee_amount?: number,
  calculated_statement_descriptor: string,
  captured: boolean,
  created: number,
  failure_code?: string
  failure_message?: string,
  fraud_details: Record<string, unknown>,
  livemode: boolean
  on_behalf_of?: string,
  order?: string,
  outcome?: Record<string, unknown>,
  paid: boolean,
  payment_method: string,
  receipt_number?: string,
  receipt_url: string,
  refunds: {
    object: 'list',
    data: Array<unknown>,
    has_more: boolean,
    url: string
  },
  review?: string
  source_transfer?: string,
  transfer?: string,
  transfer_data?: Record<string, unknown>,
  transfer_group?: string,
}

export interface ListCharges {
  object: 'list',
  url: string,
  has_more: boolean,
  data: Array<Charge>
}

// https://stripe.com/docs/api/prices/object
export interface Price {
  id: string,
  object: 'price',
  active: boolean,
  billing_scheme: 'per_unit' | 'tiered',
  created: number,
  currency: string,
  livemode: boolean,
  lookup_key: string,
  metadata: Record<string, unknown>,
  nickname: string,
  product: string,
  recurring: {
    aggregate_usage: 'sum' | 'last_during_period' | 'last_ever' | 'max',
    interval: 'day' | 'week' | 'month' | 'year',
    interval_count: number,
    usage_type: 'metered' | 'licensed'
  },
  tax_behavior: 'inclusive' | 'exclusive' | 'unspecified',
  tiers: [
    {
      flat_amount: number,
      flat_amount_decimal: string,
      unit_amount: number,
      unit_amount_decimal: string,
      up_to: number
    }
  ],
  tiers_mode: 'graduated' | 'volume',
  transform_quantity: {
    divide_by: number,
    round: 'up' | 'down'
  },
  type: 'one_time' | 'recurring'
  unit_amount: number,
  unit_amount_decimal: string

}

// https://stripe.com/docs/api/tax_rates/object
export interface TaxRate {
  id: string,
  object: 'tax_rate',
  active: boolean,
  country: string,
  description: string,
  display_name: string,
  inclusive: boolean,
  jurisdiction: string,
  metadata: Record<string, unknown>,
  percentage: number,
  state: string,
  created: number,
  livemode: boolean,
  tax_type: 'vat' | 'sales_tax' | string
}

// https://stripe.com/docs/api/subscription_items/object
export interface SubscriptionItem {
  id: string,
  object: 'subscription_item',
  billing_thresholds: {
    usage_gte: number,
  },
  created: number,
  metadata: Record<string, unknown>,
  price: Price,
  quantity: number,
  subscription: string;
  tax_rates: Array<TaxRate>
}

// https://stripe.com/docs/api/invoices/object
export interface Invoice {
  id: string,
  object: 'invoice',
  auto_advance: boolean,
  charge: string,
  collection_method: 'charge_automatically' | 'send_invoice',
  currency: string,
  customer: string,
  description: string,
  hosted_invoice_url: string,
  lines: [],
  metadata: Record<string, unknown>,
  payment_intent: PaymentIntent,
  period_end: number,
  period_start: number,
  status: 'draft' | 'open' | 'paid' | 'uncollectible' | 'void',
  subscription: string,
  total: number
}

// https://stripe.com/docs/api/subscriptions/object
export interface Subscription {
  id: string,
  object: 'subscription',
  cancel_at_period_end: boolean,
  current_period_end: number,
  current_period_start: number,
  customer: string,
  default_payment_method: string,
  items: [
    {
      object: 'list',
      data: Array<SubscriptionItem>,
      has_more: boolean,
      url: string
    }
  ]
  status: 'incomplete' | 'incomplete_expired' | 'trialing' | 'active' | 'past_due' | 'canceled' | 'unpaid',
  latest_invoice: Invoice
}
