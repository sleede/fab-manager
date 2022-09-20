# frozen_string_literal: true

# Provides methods for Product
class ProductService
  class << self
    PRODUCTS_PER_PAGE = 12

    def list(filters)
      products = Product.includes(:product_images)
      products = filter_by_active(products, filters)
      products = filter_by_categories(products, filters)
      products = filter_by_machines(products, filters)
      products = filter_by_keyword_or_reference(products, filters)
      products = filter_by_stock(products, filters)
      products = products_ordering(products, filters)

      total_count = products.count
      products = products.page(filters[:page] || 1).per(PRODUCTS_PER_PAGE)
      {
        data: products,
        page: filters[:page]&.to_i || 1,
        total_pages: products.page(1).per(PRODUCTS_PER_PAGE).total_pages,
        page_size: PRODUCTS_PER_PAGE,
        total_count: total_count
      }
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
      update_stock(product, stock_movement_params)
      product
    end

    def update(product, product_params, stock_movement_params = [])
      product_params[:amount] = amount_multiplied_by_hundred(product_params[:amount])
      product.attributes = product_params
      update_stock(product, stock_movement_params)
      product
    end

    def destroy(product)
      used_in_order = OrderItem.joins(:order).where.not('orders.state' => 'cart')
                               .exists?(orderable: product)
      raise CannotDeleteProductError if used_in_order

      ActiveRecord::Base.transaction do
        orders_with_product = Order.joins(:order_items).where(state: 'cart').where('order_items.orderable': product)
        orders_with_product.each do |order|
          ::Cart::RemoveItemService.new.call(order, product)
        end

        product.destroy
      end
    end

    private

    def filter_by_active(products, filters)
      return products if filters[:is_active].blank?

      state = filters[:is_active] == 'false' ? [nil, false, true] : true
      products.where(is_active: state)
    end

    def filter_by_categories(products, filters)
      return products if filters[:categories].blank?

      products.where(product_category_id: filters[:categories].split(','))
    end

    def filter_by_machines(products, filters)
      return products if filters[:machines].blank?

      products.includes(:machines_products).where('machines_products.machine_id': filters[:machines].split(','))
    end

    def filter_by_keyword_or_reference(products, filters)
      return products if filters[:keywords].blank?

      products.where('sku = :sku OR name ILIKE :query OR description ILIKE :query',
                     { sku: filters[:keywords], query: "%#{filters[:keywords]}%" })
    end

    def filter_by_stock(products, filters)
      products.where("(stock ->> '#{filters[:stock_type]}')::int >= #{filters[:stock_from]}") if filters[:stock_from].to_i.positive?
      products.where("(stock ->> '#{filters[:stock_type]}')::int <= #{filters[:stock_to]}") if filters[:stock_to].to_i.positive?

      products
    end

    def products_ordering(products, filters)
      key, order = filters[:sort].split('-')
      key ||= 'created_at'
      order ||= 'desc'

      products.order(key => order)
    end
  end
end
