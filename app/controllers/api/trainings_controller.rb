class API::TrainingsController < API::ApiController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_training, only: [:show, :update, :destroy]

  def index
    @requested_attributes = params[:requested_attributes]
    @trainings = policy_scope(Training)
  end

  def show
  end

  def create
    authorize Training
    @training = Training.new(training_params)
    if @training.save
      render :show, status: :created, location: @training
    else
      render json: @training.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize Training
    if params[:training][:users].present?
      members = User.where(id: valid_training_params[:users])
      members.each do |m|
        m.trainings << @training
      end
    else
      @training.update(training_params)
    end
    head :no_content
  end

  def destroy
    authorize @training
    @training.destroy
    head :no_content
  end

  private
    def set_training
      @training = Training.find(params[:id])
    end

    def valid_training_params
      params.require(:training).permit(:id, users: [])
    end

    def training_params
      params.require(:training).permit(:id, :name, :description, :machine_ids, :plan_ids, :nb_total_places, machine_ids: [], plan_ids: [])
    end
end
