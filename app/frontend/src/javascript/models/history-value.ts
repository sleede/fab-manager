import { TDateISO } from '../typings/date-iso';

export interface HistoryValue {
  id: number,
  value: string,
  created_at: TDateISO
  user: {
    id: number,
    name: string
  }
}
