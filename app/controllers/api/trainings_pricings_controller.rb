class API::TrainingsPricingsController < API::ApiController
  before_action :authenticate_user!

  def index
    @trainings_pricings = TrainingsPricing.all
  end

  def update
    if current_user.is_admin?
      @trainings_pricing = TrainingsPricing.find(params[:id])
      _trainings_pricing_params = trainings_pricing_params
      _trainings_pricing_params[:amount] = _trainings_pricing_params[:amount] * 100
      if @trainings_pricing.update(_trainings_pricing_params)
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
