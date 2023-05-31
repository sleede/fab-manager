import { TDateISO } from '../typings/date-iso';
import { Child } from './child';

export interface Member {
  maxMembers: number
  id: number
  username: string
  email: string
  profile: {
    first_name: string
    last_name: string
    phone: string
  }
  need_completion?: boolean
  group: {
    name: string
  }
  subscribed_plan?: Plan
  validated_at: TDateISO
  children: Child[]
}

interface Plan {
  id: number
  base_name: string
  name: string
  amount: number
  interval: string
  interval_count: number
  training_credit_nb: number
  training_credits: [
    {
      training_id: number
    },
    {
      training_id: number
    }
  ]
  machine_credits: [
    {
      machine_id: number
      hours: number
    },
    {
      machine_id: number
      hours: number
    }
  ]
}
