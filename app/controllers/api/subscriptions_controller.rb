# frozen_string_literal: true

# API Controller for resources of type Subscription
class API::SubscriptionsController < API::ApiController
  before_action :set_subscription, only: %i[show edit update destroy]
  before_action :authenticate_user!

  def show
    authorize @subscription
  end

  # Admins can create any subscriptions. Members can directly create subscriptions if total = 0,
  # otherwise, they must use payments_controller#confirm_payment.
  # Managers can create subscriptions for other users
  def create
    user_id = current_user.admin? || current_user.manager? ? params[:subscription][:user_id] : current_user.id
    amount = transaction_amount(current_user.admin? || (current_user.manager? && current_user.id != user_id), user_id)

    authorize SubscriptionContext.new(Subscription, amount, user_id)

    @subscription = Subscription.new(subscription_params)
    is_subscribe = Subscriptions::Subscribe.new(current_user.invoicing_profile.id, user_id)
                                           .pay_and_save(@subscription, coupon: coupon_params[:coupon_code],
                                                                        invoice: true,
                                                                        schedule: params[:subscription][:payment_schedule],
                                                                        payment_method: params[:reservation][:payment_method])

    if is_subscribe
      render :show, status: :created, location: @subscription
    else
      render json: @subscription.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize @subscription

    free_days = params[:subscription][:free] || false

    res = Subscriptions::Subscribe.new(current_user.invoicing_profile.id)
                                  .extend_subscription(@subscription, subscription_update_params[:expired_at], free_days)
    if res.is_a?(Subscription)
      @subscription = res
      render status: :created
    elsif res
      render status: :ok
    else
      render status: :unprocessable_entity
    end
  end

  private

  def transaction_amount(is_admin, user_id)
    user = User.find(user_id)
    price_details = Price.compute(is_admin,
                                  user,
                                  nil,
                                  [],
                                  plan_id: subscription_params[:plan_id],
                                  nb_places: nil,
                                  tickets: nil,
                                  coupon_code: coupon_params[:coupon_code])

    # Subtract wallet amount from total
    total = price_details[:total]
    wallet_debit = get_wallet_debit(user, total)
    total - wallet_debit
  end

  def get_wallet_debit(user, total_amount)
    wallet_amount = (user.wallet.amount * 100).to_i
    wallet_amount >= total_amount ? total_amount : wallet_amount
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_subscription
    @subscription = Subscription.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def subscription_params
    params.require(:subscription).permit(:plan_id)
  end

  def coupon_params
    params.permit(:coupon_code)
  end

  def subscription_update_params
    params.require(:subscription).permit(:expired_at)
  end
end
