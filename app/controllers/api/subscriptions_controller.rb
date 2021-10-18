# frozen_string_literal: true

# API Controller for resources of type Subscription
class API::SubscriptionsController < API::ApiController
  before_action :set_subscription, only: %i[show payment_details]
  before_action :authenticate_user!

  def show
    authorize @subscription
  end

  def payment_details
    authorize @subscription
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_subscription
    @subscription = Subscription.find(params[:id])
  end
end
