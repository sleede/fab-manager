import { Reservation } from './reservation';
import { SubscriptionRequest } from './subscription';

export interface PaymentConfirmation {
  requires_action?: boolean,
  payment_intent_client_secret?: string,
  success?: boolean,
  error?: {
    statusText: string
  }
}

export interface IntentConfirmation {
  client_secret: string
}

export enum PaymentMethod {
  Stripe = 'stripe',
  Other = ''
}

export interface CartItems {
  reservation?: Reservation,
  subscription?: SubscriptionRequest,
  coupon_code?: string
}
