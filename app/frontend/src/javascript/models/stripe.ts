export interface PIIToken {
  id: string,
  object: 'token',
  client_ip: string,
  created: number,
  livemode: boolean,
  type: 'pii',
  used: boolean
}

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
  created: Date,
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
