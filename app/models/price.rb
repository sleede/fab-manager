# frozen_string_literal: true

MINUTES_PER_HOUR = 60.0
SECONDS_PER_MINUTE = 60.0

# Store customized price for various items (Machine, Space), depending on the group and on the plan
# Also provides a static helper method to compute the price details of a shopping cart
class Price < ApplicationRecord
  belongs_to :group
  belongs_to :plan
  belongs_to :priceable, polymorphic: true

  validates :priceable, :group_id, :amount, presence: true
  validates :priceable_id, uniqueness: { scope: %i[priceable_type plan_id group_id] }

  class << self

    ##
    # @param admin {Boolean} true if the current user (ie.the user who requests the price) is an admin
    # @param user {User} The user who's reserving (or selected if an admin is reserving)
    # @param reservable {Machine|Training|Event} what the reservation is targeting
    # @param slots {Array<Slot>} when did the reservation will occur
    # @param options {plan_id:Number, nb_places:Number, tickets:Array<Ticket>, coupon_code:String, payment_schedule:Boolean}
    #        - plan_id {Number} if the user is subscribing to a plan at the same time of his reservation, specify the plan's ID here
    #        - nb_places {Number} for _reservable_ of type Event, pass here the number of booked places
    #        - tickets {Array<Ticket>} for _reservable_ of type Event, mapping of the number of seats booked per price's category
    #        - coupon_code {String} Code of the coupon to apply to the total price
    #        - payment_schedule {Boolean} if the user is requesting a payment schedule for his subscription
    # @return {Hash} total and price detail
    ##
    def compute(admin, user, reservable, slots, options = {})
      total_amount = 0
      all_elements = {}
      all_elements[:slots] = []

      # initialize Plan
      plan = if user.subscribed_plan
               new_plan_being_bought = false
               user.subscribed_plan
             elsif options[:plan_id]
               new_plan_being_bought = true
               Plan.find(options[:plan_id])
             else
               new_plan_being_bought = false
               nil
             end

      # === compute reservation price ===

      case reservable

      # Machine reservation
      when Machine
        base_amount = reservable.prices.find_by(group_id: user.group_id, plan_id: plan.try(:id)).amount
        if plan
          machine_credit = plan.machine_credits.select { |credit| credit.creditable_id == reservable.id }.first
          if machine_credit
            hours_available = credits_hours(machine_credit, user, new_plan_being_bought)
            slots.each_with_index do |slot, index|
              total_amount += get_slot_price(base_amount, slot, admin, elements: all_elements, has_credits: (index < hours_available))
            end
          else
            slots.each do |slot|
              total_amount += get_slot_price(base_amount, slot, admin, elements: all_elements)
            end
          end
        else
          slots.each do |slot|
            total_amount += get_slot_price(base_amount, slot, admin, elements: all_elements)
          end
        end

      # Training reservation
      when Training
        amount = reservable.amount_by_group(user.group_id).amount
        if plan
          # Return True if the subscription link a training credit for training reserved by the user
          space_is_creditable = plan.training_credits.select { |credit| credit.creditable_id == reservable.id }.any?

          # Training reserved by the user is free when :

          # |-> the user already has a current subscription and if space_is_creditable is true and has at least one credit available.
          if !new_plan_being_bought
            amount = 0 if user.training_credits.size < plan.training_credit_nb && space_is_creditable
          # |-> the user buys a new subscription and if space_is_creditable is true.
          else
            amount = 0 if space_is_creditable
          end
        end
        slots.each do |slot|
          total_amount += get_slot_price(amount, slot, admin, elements: all_elements, is_division: false)
        end

      # Event reservation
      when Event
        amount = reservable.amount * options[:nb_places]
        options[:tickets]&.each do |ticket|
          amount += ticket[:booked] * EventPriceCategory.find(ticket[:event_price_category_id]).amount
        end
        slots.each do |slot|
          total_amount += get_slot_price(amount, slot, admin, elements: all_elements, is_division: false)
        end

      # Space reservation
      when Space
        base_amount = reservable.prices.find_by(group_id: user.group_id, plan_id: plan.try(:id)).amount

        if plan
          space_credit = plan.space_credits.select { |credit| credit.creditable_id == reservable.id }.first
          if space_credit
            hours_available = credits_hours(space_credit, user, new_plan_being_bought)
            slots.each_with_index do |slot, index|
              total_amount += get_slot_price(base_amount, slot, admin, elements: all_elements, has_credits: (index < hours_available))
            end
          else
            slots.each do |slot|
              total_amount += get_slot_price(base_amount, slot, admin, elements: all_elements)
            end
          end
        else
          slots.each do |slot|
            total_amount += get_slot_price(base_amount, slot, admin, elements: all_elements)
          end
        end

      # No reservation (only subscription)
      when nil
        total_amount = 0

      # Unknown reservation type
      else
        raise NotImplementedError
      end

      # === compute Plan price (if any) ===
      unless options[:plan_id].nil?
        all_elements[:plan] = plan.amount
        total_amount += plan.amount
      end

      # === apply Coupon if any ===
      _amount_no_coupon = total_amount
      cs = CouponService.new
      cp = cs.validate(options[:coupon_code], user.id)
      total_amount = cs.apply(total_amount, cp)

      # == generate PaymentSchedule (if applicable) ===
      schedule = if options[:payment_schedule] && plan&.monthly_payment
                   PaymentScheduleService.new.compute(plan, _amount_no_coupon, coupon: cp)
                 else
                   nil
                 end

      total_amount = schedule[:items][0].amount if schedule

      # return result
      {
        elements: all_elements,
        total: total_amount.to_i,
        before_coupon: _amount_no_coupon.to_i,
        coupon: cp,
        schedule: schedule
      }
    end


    private

    GET_SLOT_PRICE_DEFAULT_OPTS = { has_credits: false, elements: nil, is_division: true }.freeze
    ##
    # Compute the price of a single slot, according to the base price and the ability for an admin
    # to offer the slot.
    # @param hourly_rate {Number} base price of a slot
    # @param slot {Hash} Slot object
    # @param is_admin {Boolean} true if the current user has the 'admin' role
    # @param [options] {Hash} optional parameters, allowing the following options:
    #  - elements {Array} if provided the resulting price will be append into elements.slots
    #  - has_credits {Boolean} true if the user still has credits for the given slot, false if not provided
    #  - is_division {boolean} false if the slot covers an full availability, true if it is a subdivision (default)
    # @return {Number} price of the slot
    ##
    def get_slot_price(hourly_rate, slot, is_admin, options = {})
      options = GET_SLOT_PRICE_DEFAULT_OPTS.merge(options)

      slot_rate = options[:has_credits] || (slot[:offered] && is_admin) ? 0 : hourly_rate
      real_price = if options[:is_division]
                     (slot_rate / MINUTES_PER_HOUR) * ((slot[:end_at].to_time - slot[:start_at].to_time) / SECONDS_PER_MINUTE)
                   else
                     slot_rate
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
    def credits_hours(credits, user, new_plan_being_bought)
      hours_available = credits.hours
      unless new_plan_being_bought
        user_credit = user.users_credits.find_by(credit_id: credits.id)
        hours_available = credits.hours - user_credit.hours_used if user_credit
      end
      hours_available
    end
  end
end
