# frozen_string_literal: true

# create PaymentSchedules for various items
class PaymentScheduleService
  ##
  # Compute a payment schedule for a new subscription to the provided plan
  # @param plan {Plan}
  # @param total {Number} Total amount of the current shopping cart (which includes this plan) - without coupon
  # @param coupon {Coupon} apply this coupon, if any
  ##
  def compute(plan, total, coupon: nil, subscription: nil)
    other_items = total - plan.amount
    # base monthly price of the plan
    price = plan.amount
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
      details = { recurring: per_month, subscription_id: subscription&.id }
      amount = if i.zero?
                 details[:adjustment] = adjustment.truncate
                 details[:other_items] = other_items.truncate
                 per_month + adjustment.truncate + other_items.truncate
               else
                 per_month
               end
      if coupon
        cs = CouponService.new
        if (coupon.validity_per_user == 'once' && i.zero?) || coupon.validity_per_user == 'forever'
          details[:without_coupon] = amount
          amount = cs.apply(amount, coupon)
        end
      end
      items.push PaymentScheduleItem.new(
        amount: amount,
        due_date: date,
        payment_schedule: ps,
        details: details
      )
    end
    ps.total = items.map(&:amount).reduce(:+)
    { payment_schedule: ps, items: items }
  end

  def create(subscription, total, coupon: nil, operator: nil, payment_method: nil, reservation: nil, user: nil, setup_intent_id: nil)
    subscription = reservation.generate_subscription if !subscription && reservation&.plan_id
    raise InvalidSubscriptionError unless subscription&.persisted?

    schedule = compute(subscription.plan, total, coupon: coupon, subscription: subscription)
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

  def generate_invoice(payment_schedule_item, stp_invoice = nil)
    invoice = Invoice.new(
      invoiced: payment_schedule_item.payment_schedule.scheduled,
      invoicing_profile: payment_schedule_item.payment_schedule.invoicing_profile,
      statistic_profile: payment_schedule_item.payment_schedule.user.statistic_profile,
      operator_profile_id: payment_schedule_item.payment_schedule.operator_profile_id,
      stp_payment_intent_id: stp_invoice&.payment_intent,
      payment_method: stp_invoice ? 'stripe' : nil
    )

    generate_invoice_items(invoice, payment_schedule_item, reservation: reservation, subscription: subscription)
    InvoicesService.set_total_and_coupon(invoice, user, payment_details[:coupon])
    invoice
  end

  private

  def generate_invoice_items(invoice, payment_details, reservation: nil, subscription: nil)
    if reservation
      case reservation.reservable
        # === Event reservation ===
      when Event
        InvoicesService.generate_event_item(invoice, reservation, payment_details)
        # === Space|Machine|Training reservation ===
      else
        InvoicesService.generate_generic_item(invoice, reservation, payment_details)
      end
    end

    return unless subscription || reservation&.plan_id

    subscription = reservation.generate_subscription if !subscription && reservation.plan_id
    InvoicesService.generate_subscription_item(invoice, subscription, payment_details)
  end

  def generate_reservation_item(invoice, reservation, payment_details)
    raise TypeError unless [Space, Machine, Training].include? reservation.reservable.class

    reservation.slots.each do |slot|
      description = reservation.reservable.name +
        " #{I18n.l slot.start_at, format: :long} - #{I18n.l slot.end_at, format: :hour_minute}"

      price_slot = payment_details[:elements][:slots].detect { |p_slot| p_slot[:start_at].to_time.in_time_zone == slot[:start_at] }
      invoice.invoice_items.push InvoiceItem.new(
        amount: price_slot[:price],
        description: description
      )
    end
  end

  ##
  # Generate an InvoiceItem for the given subscription and save it in invoice.invoice_items.
  # This method must be called only with a valid subscription
  ##
  def self.generate_subscription_item(invoice, subscription, payment_details)
    raise TypeError unless subscription

    invoice.invoice_items.push InvoiceItem.new(
      amount: payment_details[:elements][:plan],
      description: subscription.plan.name,
      subscription_id: subscription.id
    )
  end
end
