# frozen_string_literal: true

# Provides methods for Product
class ProductService
  class << self
    PRODUCTS_PER_PAGE = 12

    def list(filters)
      products = Product.includes(:product_images)
      if filters[:is_active].present?
        state = filters[:disabled] == 'false' ? [nil, false] : true
        products = products.where(is_active: state)
      end
      products = products.page(filters[:page]).per(PRODUCTS_PER_PAGE) if filters[:page].present?
      products
    end

    def pages(filters)
      products = Product.all
      if filters[:is_active].present?
        state = filters[:disabled] == 'false' ? [nil, false] : true
        products = Product.where(is_active: state)
      end
      products.page(1).per(PRODUCTS_PER_PAGE).total_pages
    end

    # amount params multiplied by hundred
    def amount_multiplied_by_hundred(amount)
      if amount.present?
        v = amount.to_f

        return nil if v.zero?

        return v * 100
      end
      nil
    end

    # @param product Product
    # @param stock_movements [{stock_type: string, reason: string, quantity: number|string, order_item_id: number|nil}]
    def update_stock(product, stock_movements = nil)
      remaining_stock = { internal: product.stock['internal'], external: product.stock['external'] }
      product.product_stock_movements_attributes = stock_movements&.map do |movement|
        quantity = ProductStockMovement::OUTGOING_REASONS.include?(movement[:reason]) ? -movement[:quantity].to_i : movement[:quantity].to_i
        remaining_stock[movement[:stock_type].to_sym] += quantity
        {
          stock_type: movement[:stock_type], reason: movement[:reason], quantity: quantity,
          remaining_stock: remaining_stock[movement[:stock_type].to_sym], date: DateTime.current, order_item_id: movement[:order_item_id]
        }
      end || {}
      product.stock = remaining_stock
      product
    end

    def create(product_params, stock_movement_params = [])
      product = Product.new(product_params)
      product.amount = amount_multiplied_by_hundred(product_params[:amount])
      update(product, product_params, stock_movement_params)
    end

    def update(product, product_params, stock_movement_params = [])
      product_params[:amount] = amount_multiplied_by_hundred(product_params[:amount])
      product.attributes = product_params
      update_stock(product, stock_movement_params)
      product
    end
  end
end
