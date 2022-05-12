import { Plan } from './plan';
import { TDateISO } from '../typings/date-iso';

export interface Subscription {
  id: number,
  plan_id: number,
  expired_at: TDateISO,
  canceled_at?: TDateISO,
  plan: Plan
}

export interface SubscriptionRequest {
  plan_id: number,
  start_at?: TDateISO
}

export interface UpdateSubscriptionRequest {
  id: number,
  expired_at: TDateISO,
  free: boolean
}

export interface SubscriptionPaymentDetails {
  payment_schedule: boolean,
  card: boolean
}
