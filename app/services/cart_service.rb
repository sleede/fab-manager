# frozen_string_literal: true

# Provides methods for working with cart items
class CartService
  def initialize(operator)
    @operator = operator
  end

  ##
  # For details about the expected hash format
  # @see app/frontend/src/javascript/models/payment.ts > interface ShoppingCart
  ##
  def from_hash(cart_items)
    @customer = customer(cart_items)
    plan_info = plan(cart_items)

    items = []
    cart_items[:items].each do |item|
      if ['subscription', :subscription].include?(item.keys.first)
        items.push(CartItem::Subscription.new(plan_info[:plan], @customer)) if plan_info[:new_subscription]
      elsif ['reservation', :reservation].include?(item.keys.first)
        items.push(reservable_from_hash(item[:reservation], plan_info))
      end
    end

    coupon = CartItem::Coupon.new(@customer, @operator, cart_items[:coupon_code])
    schedule = CartItem::PaymentSchedule.new(plan_info[:plan], coupon, cart_items[:payment_schedule])

    ShoppingCart.new(
      @customer,
      @operator,
      coupon,
      schedule,
      cart_items[:payment_method],
      items: items
    )
  end

  def from_payment_schedule(payment_schedule)
    @customer = payment_schedule.user
    plan = payment_schedule.payment_schedule_objects.find(&:subscription)&.subscription&.plan

    coupon = CartItem::Coupon.new(@customer, @operator, payment_schedule.coupon&.code)
    schedule = CartItem::PaymentSchedule.new(plan, coupon, true)

    items = []
    payment_schedule.payment_schedule_objects.each do |object|
      if object.subscription
        items.push(CartItem::Subscription.new(object.subscription.plan, @customer))
      elsif object.reservation
        items.push(reservable_from_payment_schedule_object(object, plan))
      end
    end

    ShoppingCart.new(
      @customer,
      @operator,
      coupon,
      schedule,
      payment_schedule.payment_method,
      items: items
    )
  end

  private

  def plan(cart_items)
    new_plan_being_bought = false
    plan = if cart_items[:items].any? { |item| ['subscription', :subscription].include?(item.keys.first) }
             index = cart_items[:items].index { |item| ['subscription', :subscription].include?(item.keys.first) }
             if cart_items[:items][index][:subscription][:plan_id]
               new_plan_being_bought = true
               Plan.find(cart_items[:items][index][:subscription][:plan_id])
             end
           elsif @customer.subscribed_plan
             @customer.subscribed_plan
           else
             nil
           end
    { plan: plan, new_subscription: new_plan_being_bought }
  end

  def customer(cart_items)
    if @operator.admin? || (@operator.manager? && @operator.id != cart_items[:customer_id])
      User.find(cart_items[:customer_id])
    else
      @operator
    end
  end

  def reservable_from_hash(cart_item, plan_info)
    reservable = cart_item[:reservable_type]&.constantize&.find(cart_item[:reservable_id])
    case reservable
    when Machine
      CartItem::MachineReservation.new(@customer,
                                       @operator,
                                       reservable,
                                       cart_item[:slots_attributes],
                                       plan: plan_info[:plan],
                                       new_subscription: plan_info[:new_subscription])
    when Training
      CartItem::TrainingReservation.new(@customer,
                                        @operator,
                                        reservable,
                                        cart_item[:slots_attributes],
                                        plan: plan_info[:plan],
                                        new_subscription: plan_info[:new_subscription])
    when Event
      CartItem::EventReservation.new(@customer,
                                     @operator,
                                     reservable,
                                     cart_item[:slots_attributes],
                                     normal_tickets: cart_item[:nb_reserve_places],
                                     other_tickets: cart_item[:tickets_attributes])
    when Space
      CartItem::SpaceReservation.new(@customer,
                                     @operator,
                                     reservable,
                                     cart_item[:slots_attributes],
                                     plan: plan_info[:plan],
                                     new_subscription: plan_info[:new_subscription])
    else
      STDERR.puts "WARNING: the reservable #{reservable} is not implemented"
      raise NotImplementedError
    end
  end

  def reservable_from_payment_schedule_object(object, plan)
    reservable = object.reservation.reservable
    case reservable
    when Machine
      CartItem::MachineReservation.new(@customer,
                                       @operator,
                                       reservable,
                                       object.reservation.slots,
                                       plan: plan,
                                       new_subscription: true)
    when Training
      CartItem::TrainingReservation.new(@customer,
                                        @operator,
                                        reservable,
                                        object.reservation.slots,
                                        plan: plan,
                                        new_subscription: true)
    when Event
      CartItem::EventReservation.new(@customer,
                                     @operator,
                                     reservable,
                                     object.reservation.slots,
                                     normal_tickets: object.reservation.nb_reserve_places,
                                     other_tickets: object.reservation.tickets)
    when Space
      CartItem::SpaceReservation.new(@customer,
                                     @operator,
                                     reservable,
                                     object.reservation.slots,
                                     plan: plan,
                                     new_subscription: true)
    else
      STDERR.puts "WARNING: the reservable #{reservable} is not implemented"
      raise NotImplementedError
    end
  end
end
