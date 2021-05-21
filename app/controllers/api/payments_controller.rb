# frozen_string_literal: true

# Abstract API Controller to be extended by each payment gateway/mean, for handling the payments processes in the front-end
class API::PaymentsController < API::ApiController
  before_action :authenticate_user!


  # This method must be overridden by the the gateways controllers that inherits API::PaymentsControllers
  def confirm_payment
    raise NoMethodError
  end

  protected

  def post_save(_gateway_item_id, _gateway_item_type); end

  def post_reservation_save(_gateway_item_id, _gateway_item_type); end

  def post_subscription_save(_gateway_item_id, _gateway_item_type); end

  def get_wallet_debit(user, total_amount)
    wallet_amount = (user.wallet.amount * 100).to_i
    wallet_amount >= total_amount ? total_amount : wallet_amount
  end

  def debit_amount(cart)
    price_details = cart.total

    # Subtract wallet amount from total
    total = price_details[:total]
    wallet_debit = get_wallet_debit(current_user, total)
    { amount: total - wallet_debit, details: price_details }
  end

  def shopping_cart
    cs = CartService.new(current_user)
    cs.from_hash(params[:cart_items])
  end

  # @param cart {ShoppingCart}
  def check_coupon(cart)
    return if cart.coupon.nil?

    cart.coupon.coupon
  end

  # @param cart {ShoppingCart}
  def check_plan(cart)
    return unless cart.subscription

    plan = cart.subscription.plan
    raise InvalidGroupError if plan.group_id != current_user.group_id
  end

  def on_success(gateway_item_id, gateway_item_type, cart)
    cart.pay_and_save(gateway_item_id, gateway_item_type)
  end

  def on_reservation_success(gateway_item_id, gateway_item_type, cart)
    is_reserve = on_success(gateway_item_id, gateway_item_type, cart)
    post_reservation_save(gateway_item_id, gateway_item_type)

    if is_reserve
      { template: 'api/reservations/show', status: :created, location: @reservation }
    else
      { json: @reservation.errors, status: :unprocessable_entity }
    end
  end

  def on_subscription_success(gateway_item_id, gateway_item_type, cart)
    is_subscribe = on_success(gateway_item_id, gateway_item_type, cart)
    post_subscription_save(gateway_item_id, gateway_item_type)

    if is_subscribe
      { template: 'api/subscriptions/show', status: :created, location: @subscription }
    else
      { json: @subscription.errors, status: :unprocessable_entity }
    end
  end
end
