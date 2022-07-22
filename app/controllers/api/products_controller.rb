# frozen_string_literal: true

# API Controller for resources of type Product
# Products are used in store
class API::ProductsController < API::ApiController
  before_action :authenticate_user!, except: %i[index show]
  before_action :set_product, only: %i[show update destroy]

  def index
    @products = ProductService.list
  end

  def show; end

  def create
    authorize Product
    @product = Product.new(product_params)
    @product.amount = nil if @product.amount.zero?
    @product.amount *= 100 if @product.amount.present?
    if @product.save
      render status: :created
    else
      render json: @product.errors.full_messages, status: :unprocessable_entity
    end
  end

  def update
    authorize @product

    product_parameters = product_params
    product_parameters[:amount] = nil if product_parameters[:amount].zero?
    product_parameters[:amount] = product_parameters[:amount] * 100 if product_parameters[:amount].present?
    if @product.update(product_parameters)
      render status: :ok
    else
      render json: @product.errors.full_messages, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @product
    @product.destroy
    head :no_content
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :slug, :sku, :description, :is_active,
                                    :product_category_id, :amount, :quantity_min,
                                    :low_stock_alert, :low_stock_threshold, machine_ids: [])
  end
end
