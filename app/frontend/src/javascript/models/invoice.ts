export interface Invoice {
  id: number,
  created_at: Date,
  reference: string,
  avoir_date: Date,
  description: string
  user_id: number,
  total: number,
  name: string,
  has_avoir: boolean,
  is_avoir: boolean,
  is_subscription_invoice: boolean,
  is_online_card: boolean,
  date: Date,
  chained_footprint: boolean,
  main_object: {
    type: string,
    id: number
  },
  items: {
    id: number,
    amount: number,
    description: string,
    avoir_item_id: number
  }
}
