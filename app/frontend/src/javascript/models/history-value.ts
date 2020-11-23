export interface HistoryValue {
  id: number,
  value: string,
  created_at: Date
  user: {
    id: number,
    name: string
  }
}
