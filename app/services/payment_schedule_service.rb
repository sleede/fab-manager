# frozen_string_literal: true

# create PaymentSchedules for various items
class PaymentScheduleService
  ##
  # Compute a payment schedule for a new subscription to the provided plan
  # @param plan {Plan}
  # @param total {Number} Total amount of the current shopping cart (which includes this plan)
  # @param coupon {Coupon} apply this coupon, if any
  ##
  def compute(plan, total, coupon = nil)
    price = if coupon
              cs = CouponService.new
              cs.ventilate(total, plan.amount, coupon)
            else
              plan.amount
            end
    ps = PaymentSchedule.new(scheduled: plan, total: price, coupon: coupon)
    deadlines = plan.duration / 1.month
    per_month = (price / deadlines).truncate
    adjustment = if per_month * deadlines != price
                   price - (per_month * deadlines)
                 else
                   0
                 end
    items = []
    (0..deadlines - 1).each do |i|
      date = DateTime.current + i.months
      items.push PaymentScheduleItem.new(
        amount: per_month + adjustment,
        due_date: date,
        payment_schedule: ps
      )
      adjustment = 0
    end
    { payment_schedule: ps, items: items }
  end
end
