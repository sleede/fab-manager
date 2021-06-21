
export interface IndexFilter {
  key: 'group_id' | 'priceable_id' | 'priceable_type',
  value: number|string,
}

export interface PrepaidPack {
  id?: number,
  priceable_id: string,
  priceable_type: string,
  group_id: number,
  validity_interval?: 'day' | 'week' | 'month' | 'year',
  validity_count?: number,
  minutes: number,
  amount: number,
  usages?: number,
}
