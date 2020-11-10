# frozen_string_literal: true

# create PaymentSchedules for various items
class PaymentScheduleService
  ##
  # Compute a payment schedule for a new subscription to the provided plan
  # @param plan {Plan}
  # @param total {Number} Total amount of the current shopping cart (which includes this plan) - without coupon
  # @param coupon {Coupon} apply this coupon, if any
  ##
  def compute(plan, total, coupon = nil)
    other_items = total - plan.amount
    price = if coupon
              cs = CouponService.new
              other_items = cs.ventilate(total, other_items, coupon)
              cs.ventilate(total, plan.amount, coupon)
            else
              plan.amount
            end
    ps = PaymentSchedule.new(scheduled: plan, total: price + other_items, coupon: coupon)
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
      amount = if i.zero?
                 per_month + adjustment + other_items
               else
                 per_month
               end
      items.push PaymentScheduleItem.new(
        amount: amount,
        due_date: date,
        payment_schedule: ps
      )
    end
    { payment_schedule: ps, items: items }
  end

  def create(subscription, total, coupon, operator, payment_method)
    schedule = compute(subscription.plan, total, coupon)
    ps = schedule[:payment_schedule]
    items = schedule[:items]

    ps.scheduled = subscription
    ps.payment_method = payment_method
    ps.operator_profile_id = operator
    items.each do |item|
      item.payment_schedule = ps
    end
  end
end
