# frozen_string_literal: true

# authorized 3rd party softwares can manage the machines through the OpenAPI
class OpenAPI::V1::MachinesController < OpenAPI::V1::BaseController
  extend OpenAPI::ApiDoc
  expose_doc

  before_action :set_machine, only: %i[show update destroy]

  def index
    @machines = Machine.order(:created_at)
  end

  def create
    @machine = Machine.new(machine_params)
    if @machine.save
      render :show, status: :created, location: @machine
    else
      render json: @machine.errors, status: :unprocessable_entity
    end
  end

  def update
    if @machine.update(machine_params)
      render :show, status: :ok, location: @machine
    else
      render json: @machine.errors, status: :unprocessable_entity
    end
  end

  def show; end

  def destroy
    if @machine.destroyable?
      @machine.destroy
      head :no_content
    else
      render json: { error: 'has existing reservations' }, status: :unprocessable_entity
    end
  end

  private

  def machine_params
    params.require(:machine).permit(:name, :description, :spec, :disabled,
                                    machine_image_attributes: [:attachment])
  end

  def set_machine
    @machine = Machine.friendly.find(params[:id])
  end
end
