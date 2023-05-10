# frozen_string_literal: true

# Provides methods for working with cart items
class CartService
  def initialize(operator)
    @operator = operator
  end

  # For details about the expected hash format
  # @see app/frontend/src/javascript/models/payment.ts > interface ShoppingCart
  # @return [ShoppingCart]
  def from_hash(cart_items)
    cart_items.permit! if cart_items.is_a? ActionController::Parameters

    @customer = customer(cart_items)
    plan_info = plan(cart_items)

    items = []
    cart_items[:items].each do |item|
      if ['subscription', :subscription].include?(item.keys.first) && plan_info[:new_subscription]
        items.push(CartItem::Subscription.new(
                     plan: plan_info[:plan],
                     customer_profile: @customer.invoicing_profile,
                     start_at: item[:subscription][:start_at]
                   ))
      elsif ['reservation', :reservation].include?(item.keys.first)
        items.push(reservable_from_hash(item[:reservation], plan_info))
      elsif ['prepaid_pack', :prepaid_pack].include?(item.keys.first)
        items.push(CartItem::PrepaidPack.new(
                     prepaid_pack: PrepaidPack.find(item[:prepaid_pack][:id]),
                     customer_profile: @customer.invoicing_profile
                   ))
      elsif ['free_extension', :free_extension].include?(item.keys.first)
        items.push(CartItem::FreeExtension.new(
                     customer_profile: @customer.invoicing_profile,
                     subscription: plan_info[:subscription],
                     new_expiration_date: item[:free_extension][:end_at]
                   ))
      end
    end

    coupon = CartItem::Coupon.new(
      customer_profile: @customer.invoicing_profile,
      operator_profile: @operator.invoicing_profile,
      coupon: Coupon.find_by(code: cart_items[:coupon_code])
    )
    schedule = CartItem::PaymentSchedule.new(
      plan: plan_info[:plan],
      coupon: coupon,
      requested: cart_items[:payment_schedule],
      customer_profile: @customer.invoicing_profile,
      start_at: plan_info[:subscription]&.start_at
    )

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
    subscription = payment_schedule.payment_schedule_objects.find { |pso| pso.object_type == Subscription.name }&.subscription
    plan = subscription&.plan

    coupon = CartItem::Coupon.new(
      customer_profile: @customer.invoicing_profile,
      operator_profile: @operator.invoicing_profile,
      coupon: payment_schedule.coupon
    )
    schedule = CartItem::PaymentSchedule.new(
      plan: plan,
      coupon: coupon,
      requested: true,
      customer_profile: @customer.invoicing_profile,
      start_at: subscription.start_at
    )

    items = []
    payment_schedule.payment_schedule_objects.each do |object|
      if object.object_type == Subscription.name
        items.push(CartItem::Subscription.new(
                     plan: object.subscription.plan,
                     customer_profile: @customer.invoicing_profile,
                     start_at: object.subscription.start_at
                   ))
      elsif object.object_type == Reservation.name
        items.push(reservable_from_payment_schedule_object(object, plan))
      elsif object.object_type == PrepaidPack.name
        items.push(CartItem::PrepaidPack.new(
                     prepaid_pack_id: object.statistic_profile_prepaid_pack.prepaid_pack_id,
                     customer_profile: @customer.invoicing_profile
                   ))
      elsif object.object_type == OfferDay.name
        items.push(CartItem::FreeExtension.new(
                     customer_profile: @customer.invoicing_profile,
                     subscription: object.offer_day.subscription,
                     new_expiration_date: object.offer_day.end_date
                   ))
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
    subscription = nil
    plan = if cart_items[:items].any? { |item| ['subscription', :subscription].include?(item.keys.first) }
             index = cart_items[:items].index { |item| ['subscription', :subscription].include?(item.keys.first) }
             if cart_items[:items][index][:subscription][:plan_id]
               new_plan_being_bought = true
               plan = Plan.find(cart_items[:items][index][:subscription][:plan_id])
               subscription = CartItem::Subscription.new(
                 plan: plan,
                 customer_profile: @customer.invoicing_profile,
                 start_at: cart_items[:items][index][:subscription][:start_at]
               ).to_object
               plan
             end
           elsif @customer.subscribed_plan
             subscription = @customer.subscription unless @customer.subscription.expired_at < Time.current
             @customer.subscribed_plan
           else
             nil
           end
    { plan: plan, subscription: subscription, new_subscription: new_plan_being_bought }
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
      CartItem::MachineReservation.new(customer_profile: @customer.invoicing_profile,
                                       operator_profile: @operator.invoicing_profile,
                                       reservable: reservable,
                                       cart_item_reservation_slots_attributes: cart_item[:slots_reservations_attributes],
                                       plan: plan_info[:plan],
                                       new_subscription: plan_info[:new_subscription])
    when Training
      CartItem::TrainingReservation.new(customer_profile: @customer.invoicing_profile,
                                        operator_profile: @operator.invoicing_profile,
                                        reservable: reservable,
                                        cart_item_reservation_slots_attributes: cart_item[:slots_reservations_attributes],
                                        plan: plan_info[:plan],
                                        new_subscription: plan_info[:new_subscription])
    when Event
      CartItem::EventReservation.new(customer_profile: @customer.invoicing_profile,
                                     operator_profile: @operator.invoicing_profile,
                                     event: reservable,
                                     cart_item_reservation_slots_attributes: cart_item[:slots_reservations_attributes],
                                     normal_tickets: cart_item[:nb_reserve_places],
                                     cart_item_event_reservation_tickets_attributes: cart_item[:tickets_attributes] || {},
                                     cart_item_event_reservation_booking_users_attributes: cart_item[:booking_users_attributes] || {})
    when Space
      CartItem::SpaceReservation.new(customer_profile: @customer.invoicing_profile,
                                     operator_profile: @operator.invoicing_profile,
                                     reservable: reservable,
                                     cart_item_reservation_slots_attributes: cart_item[:slots_reservations_attributes],
                                     plan: plan_info[:plan],
                                     new_subscription: plan_info[:new_subscription])
    else
      Rails.logger.warn "the reservable #{reservable} is not implemented"
      raise NotImplementedError
    end
  end

  def reservable_from_payment_schedule_object(object, plan)
    reservable = object.reservation.reservable
    case reservable
    when Machine
      CartItem::MachineReservation.new(customer_profile: @customer.invoicing_profile,
                                       operator_profile: @operator.invoicing_profile,
                                       reservable: reservable,
                                       cart_item_reservation_slots_attributes: object.reservation.slots_reservations,
                                       plan: plan,
                                       new_subscription: true)
    when Training
      CartItem::TrainingReservation.new(customer_profile: @customer.invoicing_profile,
                                        operator_profile: @operator.invoicing_profile,
                                        reservable: reservable,
                                        cart_item_reservation_slots_attributes: object.reservation.slots_reservations,
                                        plan: plan,
                                        new_subscription: true)
    when Event
      CartItem::EventReservation.new(customer_profile: @customer.invoicing_profile,
                                     operator_profile: @operator.invoicing_profile,
                                     event: reservable,
                                     cart_item_reservation_slots_attributes: object.reservation.slots_reservation,
                                     normal_tickets: object.reservation.nb_reserve_places,
                                     cart_item_event_reservation_tickets_attributes: object.reservation.tickets)
    when Space
      CartItem::SpaceReservation.new(customer_profile: @customer.invoicing_profile,
                                     operator_profile: @operator.invoicing_profile,
                                     reservable: reservable,
                                     cart_item_reservation_slots_attributes: object.reservation.slots_reservations,
                                     plan: plan,
                                     new_subscription: true)
    else
      Rails.logger.warn "WARNING: the reservable #{reservable} is not implemented"
      raise NotImplementedError
    end
  end
end
