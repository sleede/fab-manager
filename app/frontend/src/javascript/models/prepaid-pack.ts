
export interface PackIndexFilter {
  group_id: number,
  priceable_id: number,
  priceable_type: string
}

export interface PrepaidPack {
  id?: number,
  priceable_id: number,
  priceable_type: string,
  group_id: number,
  validity_interval?: 'day' | 'week' | 'month' | 'year',
  validity_count?: number,
  minutes: number,
  amount: number,
  usages?: number,
}
