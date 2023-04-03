# frozen_string_literal: true

# API Controller for resources of type PlanCategory
# PlanCategory are used to sort plans
class API::PlanCategoriesController < API::APIController
  before_action :authenticate_user!, except: :index
  before_action :set_category, only: %i[show update destroy]

  def index
    @categories = PlanCategory.order(weight: :desc)
  end

  def show; end

  def create
    authorize PlanCategory

    @category = PlanCategory.new(plan_category_params)
    if @category.save
      render :show, status: :created, location: @category
    else
      render json: @category.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize @category
    if @category.update(plan_category_params)
      render :show, status: :ok
    else
      render json: @category.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @category
    @category.destroy
    head :no_content
  end

  private

  def set_category
    @category = PlanCategory.find(params[:id])
  end

  def plan_category_params
    params.require(:plan_category).permit(:name, :weight, :description)
  end
end
