import { HistoryValue } from './history-value';

export interface Setting {
  name: string,
  value: string,
  last_update: Date,
  history: Array<HistoryValue>
}
