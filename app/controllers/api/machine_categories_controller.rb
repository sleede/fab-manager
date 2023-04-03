# frozen_string_literal: true

# API Controller for resources of type Machine Category
# Categories are used to classify Machine
class API::MachineCategoriesController < API::APIController
  before_action :authenticate_user!, except: [:index]
  before_action :set_machine_category, only: %i[show update destroy]

  def index
    @machine_categories = MachineCategory.all.order(name: :asc)
  end

  def show; end

  def create
    authorize MachineCategory
    @machine_category = MachineCategory.new(machine_category_params)
    if @machine_category.save
      render :show, status: :created, location: @category
    else
      render json: @machine_category.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize MachineCategory
    if @machine_category.update(machine_category_params)
      render :show, status: :ok, location: @category
    else
      render json: @machine_category.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize MachineCategory
    if @machine_category.destroy
      head :no_content
    else
      render json: @machine_category.errors, status: :unprocessable_entity
    end
  end

  private

  def set_machine_category
    @machine_category = MachineCategory.find(params[:id])
  end

  def machine_category_params
    params.require(:machine_category).permit(:name, machine_ids: [])
  end
end
