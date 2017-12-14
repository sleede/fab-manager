class API::SubscriptionsController < API::ApiController
  include FablabConfiguration

  before_action :set_subscription, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!

  def show
    authorize @subscription
  end

  def create
    if fablab_plans_deactivated?
      head 403
    else
      if current_user.is_admin?
        @subscription = Subscription.find_or_initialize_by(user_id: subscription_params[:user_id])
        @subscription.attributes = subscription_params
        is_subscribe = @subscription.save_with_local_payment(true, coupon_params[:coupon_code])
      else
        @subscription = Subscription.find_or_initialize_by(user_id: current_user.id)
        @subscription.attributes = subscription_params
        is_subscribe = @subscription.save_with_payment(true, coupon_params[:coupon_code])
      end
      if is_subscribe
        render :show, status: :created, location: @subscription
      else
        render json: @subscription.errors, status: :unprocessable_entity
      end
    end
  end

  def update
    authorize @subscription

    free_days = params[:subscription][:free] == true

    if @subscription.extend_expired_date(subscription_update_params[:expired_at], free_days)
      ex_expired_at = @subscription.previous_changes[:expired_at].first
      @subscription.user.generate_admin_invoice(free_days, ex_expired_at)
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
      begin
        Stripe::Token.retrieve(token)
      rescue Stripe::InvalidRequestError => e
        @subscription.errors[:card_token] << e.message
        false
      end
    end
end
