# frozen_string_literal: true

# API Controller for managing Training prices
class API::TrainingsPricingsController < API::ApiController
  before_action :authenticate_user!

  def index
    @trainings_pricings = TrainingsPricing.all
  end

  def update
    if current_user.admin?
      @trainings_pricing = TrainingsPricing.find(params[:id])
      trainings_pricing_parameters = trainings_pricing_params
      trainings_pricing_parameters[:amount] = trainings_pricing_parameters[:amount] * 100
      if @trainings_pricing.update(trainings_pricing_parameters)
        render status: :ok
      else
        render status: :unprocessable_entity
      end
    else
      head 403
    end
  end

  def trainings_pricing_params
    params.require(:trainings_pricing).permit(:amount)
  end
end
