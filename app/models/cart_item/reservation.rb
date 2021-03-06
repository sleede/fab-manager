# frozen_string_literal: true

MINUTES_PER_HOUR = 60.0
SECONDS_PER_MINUTE = 60.0

GET_SLOT_PRICE_DEFAULT_OPTS = { has_credits: false, elements: nil, is_division: true, prepaid: { minutes: 0 } }.freeze

# A generic reservation added to the shopping cart
class CartItem::Reservation < CartItem::BaseItem
  def initialize(customer, operator, reservable, slots)
    @customer = customer
    @operator = operator
    @reservable = reservable
    @slots = slots
    super
  end

  def price
    base_amount = @reservable.prices.find_by(group_id: @customer.group_id, plan_id: @plan.try(:id)).amount
    is_privileged = @operator.privileged? && @operator.id != @customer.id
    prepaid = { minutes: PrepaidPackService.minutes_available(@customer, @reservable) }

    elements = { slots: [] }
    amount = 0

    hours_available = credits
    @slots.each_with_index do |slot, index|
      amount += get_slot_price(base_amount, slot, is_privileged,
                               elements: elements,
                               has_credits: (index < hours_available),
                               prepaid: prepaid)
    end

    { elements: elements, amount: amount }
  end

  def name
    @reservable.name
  end

  def valid?(all_items)
    pending_subscription = all_items.find { |i| i.is_a?(CartItem::Subscription) }
    @slots.each do |slot|
      availability = Availability.find(slot[:availability_id])
      next if availability.plan_ids.empty?
      next if (@customer.subscribed_plan && availability.plan_ids.include?(@customer.subscribed_plan.id)) ||
              (pending_subscription && availability.plan_ids.include?(pending_subscription.plan.id)) ||
              (@operator.manager? && @customer.id != @operator.id) ||
              @operator.admin?

      @errors[:slot] = 'slot is restricted for subscribers'
      return false
    end

    true
  end

  protected

  def credits
    0
  end

  ##
  # Compute the price of a single slot, according to the base price and the ability for an admin
  # to offer the slot.
  # @param hourly_rate {Number} base price of a slot
  # @param slot {Hash} Slot object
  # @param is_privileged {Boolean} true if the current user has a privileged role (admin or manager)
  # @param [options] {Hash} optional parameters, allowing the following options:
  #  - elements {Array} if provided the resulting price will be append into elements.slots
  #  - has_credits {Boolean} true if the user still has credits for the given slot, false if not provided
  #  - is_division {boolean} false if the slot covers a full availability, true if it is a subdivision (default)
  #  - prepaid_minutes {Number} number of remaining prepaid minutes for the customer
  # @return {Number} price of the slot
  ##
  def get_slot_price(hourly_rate, slot, is_privileged, options = {})
    options = GET_SLOT_PRICE_DEFAULT_OPTS.merge(options)

    slot_rate = options[:has_credits] || (slot[:offered] && is_privileged) ? 0 : hourly_rate
    slot_minutes = (slot[:end_at].to_time - slot[:start_at].to_time) / SECONDS_PER_MINUTE
    # apply the base price to the real slot duration
    real_price = if options[:is_division]
                   (slot_rate / MINUTES_PER_HOUR) * slot_minutes
                 else
                   slot_rate
                 end
    # subtract free minutes from prepaid packs
    if real_price.positive? && options[:prepaid][:minutes]&.positive?
      consumed = slot_minutes
      consumed = options[:prepaid][:minutes] if slot_minutes > options[:prepaid][:minutes]
      real_price = (slot_minutes - consumed) * (slot_rate / MINUTES_PER_HOUR)
      options[:prepaid][:minutes] -= consumed
    end

    unless options[:elements].nil?
      options[:elements][:slots].push(
        start_at: slot[:start_at],
        price: real_price,
        promo: (slot_rate != hourly_rate)
      )
    end
    real_price
  end

  ##
  # Compute the number of remaining hours in the users current credits (for machine or space)
  ##
  def credits_hours(credits, new_plan_being_bought = false)
    return 0 unless credits

    hours_available = credits.hours
    unless new_plan_being_bought
      user_credit = @customer.users_credits.find_by(credit_id: credits.id)
      hours_available = credits.hours - user_credit.hours_used if user_credit
    end
    hours_available
  end

  def slots_params
    @slots.map { |slot| slot.permit(:id, :start_at, :end_at, :availability_id, :offered) }
  end
end
