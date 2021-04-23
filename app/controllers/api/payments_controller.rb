# frozen_string_literal: true

# Abstract API Controller to be extended by each gateway, for handling the payments processes in the front-end
class API::PaymentsController < API::ApiController
  before_action :authenticate_user!


  # This method must be overridden by the the gateways controllers that inherits API::PaymentsControllers
  def confirm_payment
    raise NoMethodError
  end

  protected

  def get_wallet_debit(user, total_amount)
    wallet_amount = (user.wallet.amount * 100).to_i
    wallet_amount >= total_amount ? total_amount : wallet_amount
  end

  def card_amount
    cs = CartService.new(current_user)
    cart = cs.from_hash(params[:cart_items])
    price_details = cart.total

    # Subtract wallet amount from total
    total = price_details[:total]
    wallet_debit = get_wallet_debit(current_user, total)
    { amount: total - wallet_debit, details: price_details }
  end

  def check_coupon
    return if coupon_params[:coupon_code].nil?

    coupon = Coupon.find_by(code: coupon_params[:coupon_code])
    raise InvalidCouponError if coupon.nil? || coupon.status(current_user.id) != 'active'
  end

  def check_plan
    plan_id = if params[:cart_items][:subscription]
                subscription_params[:plan_id]
              elsif params[:cart_items][:reservation]
                reservation_params[:plan_id]
              end

    return unless plan_id

    plan = Plan.find(plan_id)
    raise InvalidGroupError if plan.group_id != current_user.group_id
  end

  def reservation_params
    params[:cart_items].require(:reservation).permit(:reservable_id, :reservable_type, :plan_id, :nb_reserve_places,
                                                     tickets_attributes: %i[event_price_category_id booked],
                                                     slots_attributes: %i[id start_at end_at availability_id offered])
  end

  def subscription_params
    params[:cart_items].require(:subscription).permit(:plan_id)
  end

  def cart_items_params
    params[:cart_items].require(:reservation).permit(:reservable_id, :reservable_type, :plan_id, :user_id, :nb_reserve_places,
                                                     tickets_attributes: %i[event_price_category_id booked],
                                                     slots_attributes: %i[id start_at end_at availability_id offered])
  end

  def coupon_params
    params.require(:cart_items).permit(:coupon_code)
  end
end
