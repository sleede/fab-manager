class API::MachinesController < API::ApiController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_machine, only: [:edit, :update, :destroy]
  respond_to :json

  def index
    @machines = Machine.all
  end

  def show
    @machine = Machine.includes(:machine_files, :projects).friendly.find(params[:id])
  end

  def create
    authorize Machine
    @machine = Machine.new(machine_params)
    if @machine.save
      render :show, status: :created, location: @machine
    else
      render json: @machine.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize Machine
    if @machine.update(machine_params)
      render :show, status: :ok, location: @machine
    else
      render json: @machine.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize Machine
    @machine.destroy
    head :no_content
  end

  private
    def set_machine
      @machine = Machine.find(params[:id])
    end

    def machine_params
      params.require(:machine).permit(:name, :description, :spec, :plan_ids, plan_ids: [], machine_image_attributes: [:attachment],
                                      machine_files_attributes: [:id, :attachment, :_destroy])
    end

end
