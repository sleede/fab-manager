
export interface UserPackIndexFilter {
  user_id?: number,
  priceable_type: string,
  priceable_id: number
}

export interface UserPack {
  minutes_used: number,
  expires_at: Date,
  prepaid_pack: {
    minutes: number,
  }
}
