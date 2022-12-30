# frozen_string_literal: true

# Provides methods to create new cart items, based on an existing Order
class Cart::CreateCartItemService
  def initialize(order)
    @order = order
    @customer = order.user
    @operator = order.user.privileged? ? order.operator_profile.user : order.user
  end

  def create(item)
    key = item.keys.filter { |k| %w[subscription reservation prepaid_pack free_extension].include?(k) }.first
    case key
    when 'subscription', :subscription
      subscription = create_subscription(item.require(:subscription).permit!)
      update_reservations(subscription)
      subscription
    when 'reservation', :reservation
      create_reservation(item.require(:reservation).permit!)
    when 'prepaid_pack', :prepaid_pack
      create_prepaid_pack(item.require(:prepaid_pack).permit!)
    when 'free_extension', :free_extension
      create_free_extension(item.require(:free_extension).permit!)
    else
      raise NotImplementedError, "unknown item type #{item.keys.first}"
    end
  end

  private

  def create_subscription(cart_item)
    CartItem::Subscription.new(
      plan: Plan.find(cart_item[:plan_id]),
      customer_profile: @customer.invoicing_profile,
      start_at: cart_item[:start_at]
    )
  end

  def update_reservations(new_subscription)
    @order.order_items
          .where(orderable_type: %w[CartItem::MachineReservation CartItem::SpaceReservation CartItem::TrainingReservation])
          .find_each do |reserv|
      reserv.update(plan: new_subscription.plan, new_subscription: true)
    end
  end

  def create_reservation(cart_item)
    plan_info = subscription_info
    reservable = cart_item[:reservable_type]&.constantize&.find(cart_item[:reservable_id])
    case reservable
    when Machine
      CartItem::MachineReservation.new(customer_profile: @customer.invoicing_profile,
                                       operator_profile: @operator.invoicing_profile,
                                       reservable: reservable,
                                       cart_item_reservation_slots_attributes: cart_item[:slots_reservations_attributes],
                                       plan: plan_info[:subscription]&.plan,
                                       new_subscription: plan_info[:new_subscription])
    when Training
      CartItem::TrainingReservation.new(customer_profile: @customer.invoicing_profile,
                                        operator_profile: @operator.invoicing_profile,
                                        reservable: reservable,
                                        cart_item_reservation_slots_attributes: cart_item[:slots_reservations_attributes],
                                        plan: plan_info[:subscription]&.plan,
                                        new_subscription: plan_info[:new_subscription])
    when Event
      CartItem::EventReservation.new(customer_profile: @customer.invoicing_profile,
                                     operator_profile: @operator.invoicing_profile,
                                     event: reservable,
                                     cart_item_reservation_slots_attributes: cart_item[:slots_reservations_attributes],
                                     normal_tickets: cart_item[:nb_reserve_places],
                                     cart_item_event_reservation_tickets_attributes: cart_item[:tickets_attributes] || {})
    when Space
      CartItem::SpaceReservation.new(customer_profile: @customer.invoicing_profile,
                                     operator_profile: @operator.invoicing_profile,
                                     reservable: reservable,
                                     cart_item_reservation_slots_attributes: cart_item[:slots_reservations_attributes],
                                     plan: plan_info[:subscription]&.plan,
                                     new_subscription: plan_info[:new_subscription])
    else
      raise NotImplementedError, "unknown reservable type #{reservable}"
    end
  end

  def create_prepaid_pack(cart_item)
    CartItem::PrepaidPack.new(
      prepaid_pack: PrepaidPack.find(cart_item[:id]),
      customer_profile: @customer.invoicing_profile
    )
  end

  def create_free_extension(cart_item)
    plan_info = subscription_info
    CartItem::FreeExtension.new(
      customer_profile: @customer.invoicing_profile,
      subscription: plan_info[:subscription],
      new_expiration_date: cart_item[:end_at]
    )
  end

  def subscription_info
    cart_subscription = @order.order_items.find_by(orderable_type: 'CartItem::Subscription')
    if cart_subscription
      { subscription: cart_subscription, new_subscription: true }
    elsif @customer.subscribed_plan
      { subscription: @customer.subscription, new_subscription: false } unless @customer.subscription.expired_at < DateTime.current
    else
      { subscription: nil, new_subscription: false }
    end
  end
end
