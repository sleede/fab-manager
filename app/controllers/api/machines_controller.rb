# frozen_string_literal: true

# API Controller for resources of type Machine
class API::MachinesController < API::APIController
  before_action :authenticate_user!, except: %i[index show]
  before_action :set_machine, only: %i[update destroy]
  respond_to :json

  def index
    @machines = MachineService.list(params)
  end

  def show
    @machine = Machine.includes(:machine_files, :projects).friendly.find(params[:id])

    head :not_found if @machine.deleted_at
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
    authorize @machine
    method = @machine.destroyable? ? :destroy : :soft_destroy!
    @machine.send(method)
    head :no_content
  end

  private

  def set_machine
    @machine = Machine.find(params[:id])
  end

  def machine_params
    params.require(:machine).permit(:name, :description, :spec, :disabled, :machine_category_id, :plan_ids, :reservable,
                                    plan_ids: [], machine_image_attributes: %i[id attachment],
                                    machine_files_attributes: %i[id attachment _destroy],
                                    advanced_accounting_attributes: %i[code analytical_section])
  end
end
