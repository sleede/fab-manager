# frozen_string_literal: true

# API Controller for resources of type Subscription
class API::SubscriptionsController < API::APIController
  before_action :set_subscription, only: %i[show payment_details cancel]
  before_action :authenticate_user!

  def show
    authorize @subscription
  end

  def payment_details
    authorize @subscription
  end

  def cancel
    authorize @subscription
    if @subscription.expire
      render :show, status: :ok, location: @subscription
    else
      render json: { error: 'already expired' }, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_subscription
    @subscription = Subscription.find(params[:id])
  end
end
