# frozen_string_literal: true

# API Controller for resources of type Product
# Products are used in store
class API::ProductsController < API::APIController
  before_action :authenticate_user!, except: %i[index show]
  before_action :set_product, only: %i[update clone destroy]

  def index
    @products = ProductService.list(params, current_user)
  end

  def show
    @product = Product.includes(:product_images, :product_files).friendly.find(params[:id])
  end

  def create
    authorize Product
    @product = ProductService.create(product_params, params[:product][:product_stock_movements_attributes])
    if @product.save
      render status: :created
    else
      render json: @product.errors.full_messages, status: :unprocessable_entity
    end
  end

  def update
    authorize @product

    @product = ProductService.update(@product, product_params, params[:product][:product_stock_movements_attributes])
    if @product.save
      render status: :ok
    else
      render json: @product.errors.full_messages, status: :unprocessable_entity
    end
  end

  def clone
    authorize @product

    @product = ProductService.clone(@product, product_params)
    if @product.save
      render status: :ok
    else
      render json: @product.errors.full_messages, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @product
    begin
      ProductService.destroy(@product)
      head :no_content
    rescue StandardError => e
      render json: e, status: :unprocessable_entity
    end
  end

  def stock_movements
    authorize Product
    @movements = ProductService.stock_movements(params)
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :slug, :sku, :description, :is_active,
                                    :product_category_id, :amount, :quantity_min,
                                    :low_stock_alert, :low_stock_threshold,
                                    machine_ids: [],
                                    product_files_attributes: %i[id attachment _destroy],
                                    product_images_attributes: %i[id attachment is_main _destroy],
                                    advanced_accounting_attributes: %i[code analytical_section])
  end
end
