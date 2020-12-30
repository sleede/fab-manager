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
    adjustment = if per_month * deadlines + other_items.truncate != ps.total
                   ps.total - (per_month * deadlines + other_items.truncate)
                 else
                   0
                 end
    items = []
    (0..deadlines - 1).each do |i|
      date = DateTime.current + i.months
      details = { recurring: per_month }
      amount = if i.zero?
                 details[:adjustment] = adjustment.truncate
                 details[:other_items] = other_items.truncate
                 per_month + adjustment.truncate + other_items.truncate
               else
                 per_month
               end
      items.push PaymentScheduleItem.new(
        amount: amount,
        due_date: date,
        payment_schedule: ps,
        details: details
      )
    end
    { payment_schedule: ps, items: items }
  end

  def create(subscription, total, coupon: nil, operator: nil, payment_method: nil, reservation: nil, user: nil, setup_intent_id: nil)
    subscription = reservation.generate_subscription if !subscription && reservation&.plan_id
    raise InvalidSubscriptionError unless subscription&.persisted?

    schedule = compute(subscription.plan, total, coupon)
    ps = schedule[:payment_schedule]
    items = schedule[:items]

    ps.scheduled = reservation || subscription
    ps.payment_method = payment_method
    ps.stp_setup_intent_id = setup_intent_id
    ps.operator_profile = operator.invoicing_profile
    ps.invoicing_profile = user.invoicing_profile
    ps.payment_schedule_items = items
    items.each do |item|
      item.payment_schedule = ps
    end
    ps
  end
end
