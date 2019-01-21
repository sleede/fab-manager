# frozen_string_literal: true

# API Controller for resources of type Machine
class API::MachinesController < API::ApiController
  before_action :authenticate_user!, except: %i[index show]
  before_action :set_machine, only: %i[update destroy]
  respond_to :json

  def index
    sort_by = Setting.find_by(name: 'machines_sort_by').value || 'default'
    @machines = if sort_by == 'default'
                  Machine.includes(:machine_image, :plans)
                else
                  Machine.includes(:machine_image, :plans).order(sort_by)
                end
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
    authorize @machine
    @machine.destroy
    head :no_content
  end

  private

  def set_machine
    @machine = Machine.find(params[:id])
  end

  def machine_params
    params.require(:machine).permit(:name, :description, :spec, :disabled, :plan_ids,
                                    plan_ids: [], machine_image_attributes: [:attachment],
                                    machine_files_attributes: %i[id attachment _destroy])
  end
end
