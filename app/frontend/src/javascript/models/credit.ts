import { TDateISO } from '../typings/date-iso';

export type CreditableType = 'Training' | 'Machine' | 'Space';

export interface Credit {
  id?: number,
  creditable_id: number,
  creditable_type: CreditableType,
  created_at?: TDateISO,
  updated_at?: TDateISO,
  plan_id?: number,
  hours: number,
  creditable?: {
    id: number,
    name: string
  },
  hours_used?: number
}
