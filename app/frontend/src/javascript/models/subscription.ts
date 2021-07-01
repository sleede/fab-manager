import { Plan } from './plan';

export interface Subscription {
  id: number,
  plan_id: number,
  expired_at: Date,
  canceled_at?: Date,
  stripe: boolean,
  plan: Plan
}

export interface SubscriptionRequest {
  plan_id: number
}
