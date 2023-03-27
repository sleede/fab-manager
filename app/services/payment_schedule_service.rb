# frozen_string_literal: true

# perform various operations on PaymentSchedules
class PaymentScheduleService
  # Compute a payment schedule for a new subscription to the provided plan
  # @param plan [Plan]
  # @param total [Number] Total amount of the current shopping cart (which includes this plan) - without coupon
  # @param customer [User] the customer
  # @param coupon [Coupon] apply this coupon, if any
  # @param start_at [Time] schedule the PaymentSchedule to start in the future
  def compute(plan, total, customer, coupon: nil, start_at: nil)
    other_items = total - plan.amount
    # base monthly price of the plan
    price = plan.amount
    ps = PaymentSchedule.new(total: price + other_items, coupon: coupon)
    deadlines = plan.duration / 1.month
    per_month = (price / deadlines).truncate
    adjustment = if (per_month * deadlines) + other_items.truncate == ps.total
                   0
                 else
                   ps.total - ((per_month * deadlines) + other_items.truncate)
                 end
    items = []
    (0..deadlines - 1).each do |i|
      items.push compute_deadline(i, ps, per_month, adjustment, other_items, coupon: coupon, schedule_start_at: start_at)
    end
    ps.start_at = start_at
    ps.total = items.map(&:amount).reduce(:+)
    ps.invoicing_profile = customer.invoicing_profile
    ps.statistic_profile = customer.statistic_profile
    { payment_schedule: ps, items: items }
  end

  def compute_deadline(deadline_index, payment_schedule, price_per_month, adjustment_price, other_items_price,
                       coupon: nil, schedule_start_at: nil)
    date = (schedule_start_at || Time.current) + deadline_index.months
    details = { recurring: price_per_month }
    amount = if deadline_index.zero?
               details[:adjustment] = adjustment_price.truncate
               details[:other_items] = other_items_price.truncate
               price_per_month + adjustment_price.truncate + other_items_price.truncate
             else
               price_per_month
             end
    if coupon
      cs = CouponService.new
      if (coupon.validity_per_user == 'once' && deadline_index.zero?) || coupon.validity_per_user == 'forever'
        details[:without_coupon] = amount
        amount = cs.apply(amount, coupon)
      end
    end
    PaymentScheduleItem.new(
      amount: amount,
      due_date: date,
      payment_schedule: payment_schedule,
      details: details
    )
  end

  def create(objects, total, customer, coupon: nil, operator: nil, payment_method: nil,
             payment_id: nil, payment_type: nil)
    subscription = objects.find { |item| item.instance_of?(Subscription) }

    schedule = compute(subscription.plan, total, customer, coupon: coupon, start_at: subscription.start_at)
    ps = schedule[:payment_schedule]
    items = schedule[:items]

    ps.payment_schedule_objects = build_objects(objects)
    ps.payment_method = payment_method
    if !payment_id.nil? && !payment_type.nil?
      pgo = PaymentGatewayObject.new(
        gateway_object_id: payment_id,
        gateway_object_type: payment_type,
        item: ps
      )
      ps.payment_gateway_objects.push(pgo)
    end
    ps.operator_profile = operator.invoicing_profile
    ps.payment_schedule_items = items
    ps
  end

  def build_objects(objects)
    res = []
    res.push(PaymentScheduleObject.new(object: objects[0], main: true))
    objects[1..].each do |object|
      res.push(PaymentScheduleObject.new(object: object))
    end
    res
  end

  # Generate the invoice associated with the given PaymentScheduleItem, with the children elements (InvoiceItems).
  # @param payment_method [String] the payment method or gateway in use
  # @param payment_id [String] the identifier of the payment as provided by the payment gateway, in case of card payment
  # @param payment_type [String] the object type of payment_id
  def generate_invoice(payment_schedule_item, payment_method: nil, payment_id: nil, payment_type: nil)
    # build the base invoice
    invoice = Invoice.new(
      invoicing_profile: payment_schedule_item.payment_schedule.invoicing_profile,
      statistic_profile: payment_schedule_item.payment_schedule.statistic_profile,
      operator_profile_id: payment_schedule_item.payment_schedule.operator_profile_id,
      payment_method: payment_method
    )
    unless payment_id.nil?
      invoice.payment_gateway_object = PaymentGatewayObject.new(gateway_object_id: payment_id, gateway_object_type: payment_type)
    end
    # complete the invoice with some InvoiceItem
    if payment_schedule_item.first?
      complete_first_invoice(payment_schedule_item, invoice)
    else
      complete_next_invoice(payment_schedule_item, invoice)
    end

    # set the total and apply any coupon
    user = payment_schedule_item.payment_schedule.user
    coupon = payment_schedule_item.payment_schedule.coupon
    set_total_and_coupon(payment_schedule_item, invoice, user, coupon)

    # save the results
    invoice.payment_schedule_item = payment_schedule_item
    invoice.save
  end

  # return a paginated list of PaymentSchedule, optionally filtered, with their associated PaymentScheduleItem
  # @param page [Number] page number, used to paginate results
  # @param size [Number] number of items per page
  # @param filters [Hash] allowed filters: reference, customer, date.
  def self.list(page, size, filters = {})
    ps = PaymentSchedule.includes(:operator_profile, :payment_schedule_items, invoicing_profile: [:user])
                        .joins(:invoicing_profile)
                        .order('payment_schedules.created_at DESC')
                        .page(page)
                        .per(size)

    unless filters[:reference].nil?
      ps = ps.where(
        'payment_schedules.reference LIKE :search',
        search: "#{filters[:reference]}%"
      )
    end
    unless filters[:customer].nil?
      # ILIKE => PostgreSQL case-insensitive LIKE
      ps = ps.where(
        'invoicing_profiles.first_name ILIKE :search OR invoicing_profiles.last_name ILIKE :search',
        search: "%#{filters[:customer]}%"
      )
    end
    unless filters[:date].nil?
      ps = ps.where(
        "date_trunc('day', payment_schedules.created_at) = :search OR date_trunc('day', payment_schedule_items.due_date) = :search",
        search: "%#{Time.zone.iso8601(filters[:date]).to_date}%"
      )
    end

    ps
  end

  ##
  # Cancel the given PaymentSchedule: cancel the remote subscription on the payment gateway, mark the PaymentSchedule as cancelled,
  # the remaining PaymentScheduleItems as canceled too, and cancel the associated Subscription.
  ##
  def self.cancel(payment_schedule)
    PaymentGatewayService.new.cancel_subscription(payment_schedule)

    # cancel all item where state != paid
    payment_schedule.ordered_items.each do |item|
      next if item.state == 'paid'

      item.update(state: 'canceled')
    end
    # cancel subscription
    subscription = payment_schedule.payment_schedule_objects.find { |pso| pso.object_type == Subscription.name }.subscription
    subscription.expire

    subscription.canceled_at
  end

  ##
  # Update the payment mean associated with the given PaymentSchedule and reset the erroneous items
  ##
  def update_payment_mean(payment_schedule, payment_mean)
    payment_schedule.update(payment_mean) && reset_erroneous_payment_schedule_items(payment_schedule)
  end

  private

  ##
  # After the payment method has been updated, we need to reset the erroneous payment schedule items
  # so the admin can confirm them to generate the invoice
  ##
  def reset_erroneous_payment_schedule_items(payment_schedule)
    results = payment_schedule.payment_schedule_items.where(state: %w[error gateway_canceled]).map do |item|
      item.update(state: item.due_date < Time.current ? 'pending' : 'new')
    end
    results.reduce(true) { |acc, item| acc && item }
  end

  ##
  # The first PaymentScheduleItem contains references to the reservation price (if any) and to the adjustment price
  # for the subscription (if any) and the wallet transaction (if any)
  ##
  def complete_first_invoice(payment_schedule_item, invoice)
    # sub-prices for the subscription and the reservation
    details = {
      subscription: payment_schedule_item.details['recurring'] + payment_schedule_item.details['adjustment']
    }

    # the subscription and reservation items
    subscription = payment_schedule_item.payment_schedule
                                        .payment_schedule_objects
                                        .find { |pso| pso.object_type == Subscription.name }
                                        .subscription
    if payment_schedule_item.payment_schedule.main_object.object_type == Reservation.name
      details[:reservation] = payment_schedule_item.details['other_items']
      reservation = payment_schedule_item.payment_schedule.main_object.reservation
    end

    # the wallet transaction
    invoice[:wallet_amount] = payment_schedule_item.payment_schedule.wallet_amount
    invoice[:wallet_transaction_id] = payment_schedule_item.payment_schedule.wallet_transaction_id

    # build the invoice items
    generate_invoice_items(invoice, details, subscription: subscription, reservation: reservation)
  end

  ##
  # The later PaymentScheduleItems only contain references to the subscription (which is recurring)
  ##
  def complete_next_invoice(payment_schedule_item, invoice)
    # the subscription item
    subscription = payment_schedule_item.payment_schedule
                                        .payment_schedule_objects
                                        .find { |pso| pso.object_type == Subscription.name }
                                        .subscription

    # sub-price for the subscription
    details = { subscription: payment_schedule_item.details['recurring'] }

    # build the invoice item
    generate_invoice_items(invoice, details, subscription: subscription)
  end

  ##
  # Generate an array of InvoiceItem according to the provided parameters and saves them in invoice.invoice_items
  ##
  def generate_invoice_items(invoice, payment_details, reservation: nil, subscription: nil)
    generate_reservation_item(invoice, reservation, payment_details) if reservation

    return unless subscription

    generate_subscription_item(invoice, subscription, payment_details, main: reservation.nil?)
  end

  ##
  # Generate a single InvoiceItem for the given reservation and save it in invoice.invoice_items.
  # This method must be called only with a valid reservation
  ##
  def generate_reservation_item(invoice, reservation, payment_details)
    raise TypeError unless [Space, Machine, Training].include? reservation.reservable.class

    description = "#{reservation.reservable.name}\n"
    reservation.slots.each do |slot|
      description += " #{I18n.l slot.start_at, format: :long} - #{I18n.l slot.end_at, format: :hour_minute}\n"
    end

    invoice.invoice_items.push InvoiceItem.new(
      amount: payment_details[:reservation],
      description: description,
      object: reservation,
      main: true
    )
  end

  ##
  # Generate an InvoiceItem for the given subscription and save it in invoice.invoice_items.
  # This method must be called only with a valid subscription
  ##
  def generate_subscription_item(invoice, subscription, payment_details, main: true)
    raise TypeError unless subscription

    invoice.invoice_items.push InvoiceItem.new(
      amount: payment_details[:subscription],
      description: subscription.plan.base_name,
      object: subscription,
      main: main
    )
  end

  ##
  # Set the total price to the invoice, summing all sub-items.
  # Additionally a coupon may be applied to this invoice to make a discount on the total price
  ##
  def set_total_and_coupon(payment_schedule_item, invoice, user, coupon = nil)
    return unless invoice

    total = invoice.invoice_items.map(&:amount).map(&:to_i).reduce(:+)

    if !coupon.nil? && ((coupon.validity_per_user == 'once' && payment_schedule_item.first?) || coupon.validity_per_user == 'forever')
      total = CouponService.new.apply(total, coupon, user.id)
      invoice.coupon_id = coupon.id
    end

    invoice.total = total
  end
end
