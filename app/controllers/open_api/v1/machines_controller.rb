# frozen_string_literal: true

# authorized 3rd party softwares can manage the machines through the OpenAPI
class OpenAPI::V1::MachinesController < OpenAPI::V1::BaseController
  extend OpenAPI::APIDoc
  expose_doc

  before_action :set_machine, only: %i[show update destroy]

  def index
    @machines = Machine.order(:created_at).where(deleted_at: nil)
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

  def show
    head :not_found if @machine.deleted_at
  end

  def destroy
    method = @machine.destroyable? ? :destroy : :soft_destroy!
    @machine.send(method)
    head :no_content
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
