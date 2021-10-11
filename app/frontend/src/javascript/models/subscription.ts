import { Plan } from './plan';

export interface Subscription {
  id: number,
  plan_id: number,
  expired_at: Date,
  canceled_at?: Date,
  plan: Plan
}

export interface SubscriptionRequest {
  plan_id: number
}

export interface UpdateSubscriptionRequest {
  id: number,
  expired_at: Date,
  free: boolean
}

export interface SubscriptionPaymentDetails {
  payment_schedule: boolean,
  card: boolean
}
