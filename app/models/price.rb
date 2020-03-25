# frozen_string_literal: true

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
    # @param [plan_id] {Number} if the user is subscribing to a plan at the same time of his reservation, specify the plan's ID here
    # @param [nb_places] {Number} for _reservable_ of type Event, pass here the number of booked places
    # @param [tickets] {Array<Ticket>} for _reservable_ of type Event, mapping of the number of seats booked per price's category
    # @param [coupon_code] {String} Code of the coupon to apply to the total price
    # @return {Hash} total and price detail
    ##
    def compute(admin, user, reservable, slots, plan_id = nil, nb_places = nil, tickets = nil, coupon_code = nil)
      total_amount = 0
      all_elements = {}
      all_elements[:slots] = []

      # initialize Plan
      if user.subscribed_plan
        plan = user.subscribed_plan
        new_plan_being_bought = false
      elsif plan_id
        plan = Plan.find(plan_id)
        new_plan_being_bought = true
      else
        plan = nil
        new_plan_being_bought = false
      end

      # === compute reservation price ===

      case reservable

      # Machine reservation
      when Machine
        base_amount = reservable.prices.find_by(group_id: user.group_id, plan_id: plan.try(:id)).amount
        if plan
          space_credit = plan.machine_credits.select { |credit| credit.creditable_id == reservable.id }.first
          if space_credit
            hours_available = credits_hours(space_credit, user, new_plan_being_bought)
            slots.each_with_index do |slot, index|
              total_amount += get_slot_price(base_amount, slot, admin, all_elements, (index < hours_available))
            end
          else
            slots.each do |slot|
              total_amount += get_slot_price(base_amount, slot, admin, all_elements)
            end
          end
        else
          slots.each do |slot|
            total_amount += get_slot_price(base_amount, slot, admin, all_elements)
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
          total_amount += get_slot_price(amount, slot, admin, all_elements)
        end

      # Event reservation
      when Event
        amount = reservable.amount * nb_places
        tickets&.each do |ticket|
          amount += ticket[:booked] * EventPriceCategory.find(ticket[:event_price_category_id]).amount
        end
        slots.each do |slot|
          total_amount += get_slot_price(amount, slot, admin, all_elements)
        end

      # Space reservation
      when Space
        base_amount = reservable.prices.find_by(group_id: user.group_id, plan_id: plan.try(:id)).amount

        if plan
          space_credit = plan.space_credits.select { |credit| credit.creditable_id == reservable.id }.first
          if space_credit
            hours_available = credits_hours(space_credit, user, new_plan_being_bought)
            slots.each_with_index do |slot, index|
              total_amount += get_slot_price(base_amount, slot, admin, all_elements, (index < hours_available))
            end
          else
            slots.each do |slot|
              total_amount += get_slot_price(base_amount, slot, admin, all_elements)
            end
          end
        else
          slots.each do |slot|
            total_amount += get_slot_price(base_amount, slot, admin, all_elements)
          end
        end

      # No reservation (only subscription)
      when nil
        total_amount = 0

      # Unknown reservation type
      else
        raise NotImplementedError
      end

      # === compute Plan price if any ===
      unless plan_id.nil?
        all_elements[:plan] = plan.amount
        total_amount += plan.amount
      end

      # === apply Coupon if any ===
      _amount_no_coupon = total_amount
      total_amount = CouponService.new.apply(total_amount, coupon_code)

      # return result
      { elements: all_elements, total: total_amount.to_i, before_coupon: _amount_no_coupon.to_i }
    end


    private

    ##
    # Compute the price of a single slot, according to the base price and the ability for an admin
    # to offer the slot.
    # @param base_amount {Number} base price of a slot
    # @param slot {Hash} Slot object
    # @param is_admin {Boolean} true if the current user has the 'admin' role
    # @param [elements] {Array} optional, if provided the resulting price will be append into elements.slots
    # @param [has_credits] {Boolean} true if the user still has credits for the given slot
    # @return {Number} price of the slot
    ##
    def get_slot_price(base_amount, slot, is_admin, elements = nil, has_credits = false)
      ii_amount = has_credits || (slot[:offered] && is_admin) ? 0 : base_amount
      elements[:slots].push(start_at: slot[:start_at], price: ii_amount, promo: (ii_amount != base_amount)) unless elements.nil?
      ii_amount
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
