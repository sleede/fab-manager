# frozen_string_literal: true

# A generic reservation added to the shopping cart
class CartItem::Reservation < CartItem::BaseItem
  MINUTES_PER_HOUR = 60.0
  SECONDS_PER_MINUTE = 60.0

  GET_SLOT_PRICE_DEFAULT_OPTS = { has_credits: false, elements: nil, is_division: true, prepaid: { minutes: 0 }, custom_duration: nil }.freeze

  def reservable
    nil
  end

  def plan
    nil
  end

  def operator
    operator_profile.user
  end

  def customer
    customer_profile.user
  end

  def price
    is_privileged = operator.privileged? && operator.id != customer.id
    prepaid = { minutes: PrepaidPackService.minutes_available(customer, reservable) }

    raise InvalidGroupError, I18n.t('cart_items.group_subscription_mismatch') if !@plan.nil? && @customer.group_id != @plan.group_id

    elements = { slots: [] }
    amount = 0

    hours_available = credits
    grouped_slots.each_value do |slots|
      prices = applicable_prices(slots)
      slots.each_with_index do |slot, index|
        amount += get_slot_price_from_prices(prices, slot, is_privileged,
                                             elements: elements,
                                             has_credits: (index < hours_available),
                                             prepaid: prepaid)
      end
    end

    { elements: elements, amount: amount }
  end

  def name
    reservable&.name
  end

  def valid?(all_items = [])
    pending_subscription = all_items.find { |i| i.is_a?(CartItem::Subscription) }

    reservation_deadline_minutes = Setting.get('reservation_deadline').to_i
    reservation_deadline = reservation_deadline_minutes.minutes.since

    cart_item_reservation_slots.each do |sr|
      slot = sr.slot
      if slot.nil?
        errors.add(:slot, I18n.t('cart_item_validation.slot'))
        return false
      end

      availability = slot.availability
      if availability.nil?
        errors.add(:availability, I18n.t('cart_item_validation.availability'))
        return false
      end

      if slot.full?
        errors.add(:slot, I18n.t('cart_item_validation.full'))
        return false
      end

      if slot.start_at < reservation_deadline && !operator.privileged?
        errors.add(:slot, I18n.t('cart_item_validation.deadline', { MINUTES: reservation_deadline_minutes }))
        return false
      end

      next if availability.plan_ids.empty?
      next if required_subscription?(availability, pending_subscription)

      errors.add(:availability, I18n.t('cart_item_validation.restricted'))
      return false
    end

    true
  end

  def to_object
    ::Reservation.new(
      reservable_id: reservable_id,
      reservable_type: reservable_type,
      slots_reservations_attributes: slots_params,
      statistic_profile_id: StatisticProfile.find_by(user: customer).id
    )
  end

  protected

  def credits
    0
  end

  ##
  # Group the slots by date, if the extended_prices_in_same_day option is set to true
  ##
  def grouped_slots
    return { all: cart_item_reservation_slots } unless Setting.get('extended_prices_in_same_day')

    cart_item_reservation_slots.group_by { |slot| slot.slot[:start_at].to_date }
  end

  ##
  # Compute the price of a single slot, according to the list of applicable prices.
  # @param prices {{ prices: Array<{price: Price, duration: number}> }} list of prices to use with the current reservation
  # @see get_slot_price
  ##
  def get_slot_price_from_prices(prices, slot_reservation, is_privileged, options = {})
    options = GET_SLOT_PRICE_DEFAULT_OPTS.merge(options)

    slot_minutes = (slot_reservation.slot[:end_at].to_time - slot_reservation.slot[:start_at].to_time) / SECONDS_PER_MINUTE
    price = prices[:prices].find { |p| p[:duration] <= slot_minutes && p[:duration].positive? }
    price = prices[:prices].first if price.nil?
    hourly_rate = ((Rational(price[:price].amount.to_f) / Rational(price[:price].duration)) * Rational(MINUTES_PER_HOUR)).to_f

    # apply the base price to the real slot duration
    real_price = get_slot_price(hourly_rate, slot_reservation, is_privileged, options)

    price[:duration] -= slot_minutes

    real_price
  end

  ##
  # Compute the price of a single slot, according to the base price and the ability for an admin
  # to offer the slot.
  # @param hourly_rate {Number} base price of a slot
  # @param slot_reservation {CartItem::ReservationSlot}
  # @param is_privileged {Boolean} true if the current user has a privileged role (admin or manager)
  # @param [options] {Hash} optional parameters, allowing the following options:
  #  - elements {Array} if provided the resulting price will be append into elements.slots
  #  - has_credits {Boolean} true if the user still has credits for the given slot, false if not provided
  #  - is_division {boolean} false if the slot covers a full availability, true if it is a subdivision (default)
  #  - prepaid_minutes {Number} number of remaining prepaid minutes for the customer
  # @return {Number} price of the slot
  ##
  def get_slot_price(hourly_rate, slot_reservation, is_privileged, options = {})
    options = GET_SLOT_PRICE_DEFAULT_OPTS.merge(options)

    slot_rate = options[:has_credits] || (slot_reservation[:offered] && is_privileged) ? 0 : hourly_rate
    slot_minutes = (slot_reservation.slot[:end_at].to_time - slot_reservation.slot[:start_at].to_time) / SECONDS_PER_MINUTE
    # apply the base price to the real slot duration
    real_price = if options[:is_division]
                   ((Rational(slot_rate) / Rational(MINUTES_PER_HOUR)) * Rational(slot_minutes)).to_f
                 else
                   slot_rate
                 end
    # subtract free minutes from prepaid packs
    if real_price.positive? && options[:prepaid][:minutes]&.positive?
      consumed = slot_minutes
      consumed = options[:prepaid][:minutes] if slot_minutes > options[:prepaid][:minutes]
      real_price = (Rational(slot_minutes - consumed) * (Rational(slot_rate) / Rational(MINUTES_PER_HOUR))).to_f
      options[:prepaid][:minutes] -= consumed
    end

    unless options[:elements].nil?
      options[:elements][:slots].push(
        start_at: slot_reservation.slot[:start_at],
        price: real_price,
        promo: (slot_rate != hourly_rate)
      )
    end
    real_price
  end

  # We determine the list of prices applicable to current reservation
  # The longest available price is always used in priority.
  # Eg. If the reservation is for 12 hours, and there are prices for 3 hours, 7 hours,
  # and the base price (1 hours), we use the 7 hours price, then 3 hours price, and finally the base price twice (7+3+1+1 = 12).
  # All these prices are returned to be applied to the reservation.
  def applicable_prices(slots_reservations)
    total_duration = slots_reservations.map do |slot|
      (slot.slot[:end_at].to_time - slot.slot[:start_at].to_time) / SECONDS_PER_MINUTE
    end.reduce(:+)
    rates = { prices: [] }

    remaining_duration = total_duration
    while remaining_duration.positive?
      max_duration = reservable&.prices&.where(group_id: customer.group_id, plan_id: plan.try(:id))
                       &.where(Price.arel_table[:duration].lteq(remaining_duration))
                       &.maximum(:duration)
      max_duration = 60 if max_duration.nil?
      max_duration_price = reservable&.prices&.find_by(group_id: customer.group_id, plan_id: plan.try(:id), duration: max_duration)

      current_duration = [remaining_duration, max_duration].min
      rates[:prices].push(price: max_duration_price, duration: current_duration)

      remaining_duration -= current_duration
    end

    rates[:prices].sort! { |a, b| b[:duration] <=> a[:duration] }
    rates
  end

  ##
  # Compute the number of remaining hours in the users current credits (for machine or space)
  ##
  def credits_hours(credits, new_plan_being_bought: false)
    return 0 unless credits

    hours_available = credits.hours
    unless new_plan_being_bought
      user_credit = customer.users_credits.find_by(credit_id: credits.id)
      hours_available = credits.hours - user_credit.hours_used if user_credit
    end
    hours_available
  end

  def slots_params
    cart_item_reservation_slots.map { |sr| { id: sr.slots_reservation_id, slot_id: sr.slot_id, offered: sr.offered } }
  end

  ##
  # Check if the given availability requires a valid subscription. If so, check if the current customer
  # has the required susbcription, otherwise, check if the operator is privileged
  ##
  def required_subscription?(availability, pending_subscription)
    (customer.subscribed_plan && availability.plan_ids.include?(customer.subscribed_plan.id)) ||
      (pending_subscription && availability.plan_ids.include?(pending_subscription.plan.id)) ||
      (operator.manager? && customer.id != operator.id) ||
      operator.admin?
  end
end
