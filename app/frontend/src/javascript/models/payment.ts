import { Reservation } from './reservation';

export interface PaymentConfirmation {
  requires_action?: boolean,
  payment_intent_client_secret?: string,
  success?: boolean,
  error?: {
    statusText: string
  },
}

export enum PaymentMethod {
  Stripe = 'stripe',
  Other = ''
}

export interface CartItems {
  reservation: Reservation,
  subscription: {
    plan_id: number,
    user_id: number,
    payment_schedule: boolean,
    payment_method: PaymentMethod
  },
  coupon_code: string
}
