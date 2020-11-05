export interface PaymentScheduleItem {
  id: number,
  price: number,
  due_date: Date
}

export interface PaymentSchedule {
  id: number,
  scheduled_type: string,
  scheduled_id: number,
  total: number,
  stp_subscription_id: string,
  reference: string,
  payment_method: string,
  wallet_amount: number,
  items: Array<PaymentScheduleItem>
}
