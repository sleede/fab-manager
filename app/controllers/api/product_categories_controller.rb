# frozen_string_literal: true

# API Controller for resources of type ProductCategory
# ProductCategories are used to group Products
class API::ProductCategoriesController < API::APIController
  before_action :authenticate_user!, except: :index
  before_action :set_product_category, only: %i[update destroy position]

  def index
    @product_categories = ProductCategoryService.list
  end

  def show
    @product_category = ProductCategory.friendly.find(params[:id])
  end

  def create
    authorize ProductCategory
    @product_category = ProductCategory.new(product_category_params)
    if @product_category.save
      render status: :created
    else
      render json: @product_category.errors.full_messages, status: :unprocessable_entity
    end
  end

  def update
    authorize @product_category

    if @product_category.update(product_category_params)
      render status: :ok
    else
      render json: @product_category.errors.full_messages, status: :unprocessable_entity
    end
  end

  def position
    authorize @product_category
    render json: @product_category, status: :not_modified and return if @product_category.position == params[:position]

    if @product_category.insert_at(params[:position])
      render :show
    else
      render json: @product_category.errors.full_messages, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @product_category
    ProductCategoryService.destroy(@product_category)
    head :no_content
  end

  private

  def set_product_category
    @product_category = ProductCategory.find(params[:id])
  end

  def product_category_params
    params.require(:product_category).permit(:name, :parent_id, :slug)
  end
end
