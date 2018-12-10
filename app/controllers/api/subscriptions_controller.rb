class API::SubscriptionsController < API::ApiController
  include FablabConfiguration

  before_action :set_subscription, only: %i[show edit update destroy]
  before_action :authenticate_user!

  def show
    authorize @subscription
  end

  def create
    if fablab_plans_deactivated?
      head 403
    else
      method = current_user.is_admin? ? :local : :stripe
      user_id = current_user.is_admin? ? subscription_params[:user_id] : current_user.id

      @subscription = Subscription.new(subscription_params)
      is_subscribe = Subscriptions::Subscribe.new(user_id)
                                             .pay_and_save(@subscription, method, coupon_params[:coupon_code], true)

      if is_subscribe
        render :show, status: :created, location: @subscription
      else
        render json: @subscription.errors, status: :unprocessable_entity
      end
    end
  end

  def update
    authorize @subscription

    free_days = params[:subscription][:free] || false

    if Subscriptions::Subscribe.new(@subscription.user_id)
                               .extend_subscription(@subscription, subscription_update_params[:expired_at], free_days)
      render status: :ok
    else
      render status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_subscription
    @subscription = Subscription.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def subscription_params
    params.require(:subscription).permit(:plan_id, :user_id, :card_token)
  end

  def coupon_params
    params.permit(:coupon_code)
  end

  def subscription_update_params
    params.require(:subscription).permit(:expired_at)
  end

  # TODO refactor subscriptions logic and move this in model/validator
  def valid_card_token?(token)
    Stripe::Token.retrieve(token)
  rescue Stripe::InvalidRequestError => e
    @subscription.errors[:card_token] << e.message
    false
  end
end
