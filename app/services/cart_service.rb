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
      if item.keys.first == 'subscription'
        items.push(CartItem::Subscription.new(plan_info[:plan], @customer)) if plan_info[:new_subscription]
      elsif item.keys.first == 'reservation'
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

  private

  def plan(cart_items)
    new_plan_being_bought = false
    plan = if cart_items[:items].any? { |item| item.keys.first == 'subscription' }
             index = cart_items[:items].index { |item| item.keys.first == 'subscription' }
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
end
