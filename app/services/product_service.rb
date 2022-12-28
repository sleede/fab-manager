# frozen_string_literal: true

require './app/helpers/application_helper'

# Provides methods for Product
class ProductService
  class << self
    include ApplicationHelper

    PRODUCTS_PER_PAGE = 12
    MOVEMENTS_PER_PAGE = 10

    def list(filters, operator)
      products = Product.includes(:product_images)
      products = filter_by_active(products, filters)
      products = filter_by_categories(products, filters)
      products = filter_by_machines(products, filters)
      products = filter_by_keyword_or_reference(products, filters)
      products = filter_by_stock(products, filters, operator)
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
      return to_centimes(amount) if amount.present?

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
      notify_on_low_stock(product, stock_movements)
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

    def clone(product, product_params)
      new_product = product.dup
      new_product.name = product_params[:name]
      new_product.sku = product_params[:sku]
      new_product.is_active = product_params[:is_active]
      new_product.stock['internal'] = 0
      new_product.stock['external'] = 0
      new_product.machine_ids = product.machine_ids
      new_product.machine_ids = product.machine_ids
      product.product_images.each do |image|
        pi = new_product.product_images.build
        pi.is_main = image.is_main
        pi.attachment = File.open(image.attachment.file.file)
      end
      product.product_files.each do |file|
        pf = new_product.product_files.build
        pf.attachment = File.open(file.attachment.file.file)
      end
      new_product
    end

    def destroy(product)
      used_in_order = OrderItem.joins(:order).where.not('orders.state' => 'cart')
                               .exists?(orderable: product)
      raise CannotDeleteProductError, I18n.t('errors.messages.product_in_use') if used_in_order

      ActiveRecord::Base.transaction do
        orders_with_product = Order.joins(:order_items).where(state: 'cart').where('order_items.orderable': product)
        orders_with_product.each do |order|
          ::Cart::RemoveItemService.new.call(order, product)
        end

        product.destroy
      end
    end

    def stock_movements(filters)
      movements = ProductStockMovement.where(product_id: filters[:id]).order(date: :desc)
      movements = filter_by_stock_type(movements, filters)
      movements = filter_by_reason(movements, filters)

      total_count = movements.count
      movements = movements.page(filters[:page] || 1).per(MOVEMENTS_PER_PAGE)
      {
        data: movements,
        page: filters[:page]&.to_i || 1,
        total_pages: movements.page(1).per(MOVEMENTS_PER_PAGE).total_pages,
        page_size: MOVEMENTS_PER_PAGE,
        total_count: total_count
      }
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

      products.where('sku = :sku OR lower(f_unaccent(name)) ILIKE :query OR lower(f_unaccent(description)) ILIKE :query',
                     { sku: (filters[:keywords]), query: "%#{I18n.transliterate(filters[:keywords])}%" })
    end

    def filter_by_stock(products, filters, operator)
      return products if filters[:stock_type] == 'internal' && !operator&.privileged?

      products = if filters[:stock_from].to_i.positive?
                   products.where('(stock ->> ?)::int >= ?', filters[:stock_type], filters[:stock_from])
                 elsif filters[:store] == 'true' && filters[:is_available] == 'true'
                   products.where('(stock ->> ?)::int >= quantity_min', filters[:stock_type])
                 else
                   products
                 end
      products = products.where('(stock ->> ?)::int <= ?', filters[:stock_type], filters[:stock_to]) if filters[:stock_to].to_i != 0

      products
    end

    def products_ordering(products, filters)
      key, order = filters[:sort]&.split('-')
      key ||= 'created_at'
      order ||= 'desc'

      if key == 'amount'
        products.order("COALESCE(amount, 0) #{order.upcase}")
      else
        products.order(key => order)
      end
    end

    def filter_by_stock_type(movements, filters)
      return movements if filters[:stock_type].blank? || filters[:stock_type] == 'all'

      movements.where(stock_type: filters[:stock_type])
    end

    def filter_by_reason(movements, filters)
      return movements if filters[:reason].blank?

      movements.where(reason: filters[:reason])
    end

    def notify_on_low_stock(product, stock_movements = nil)
      return product unless product.low_stock_alert
      return product unless product.low_stock_threshold

      affected_stocks = stock_movements&.map { |m| m[:stock_type] }&.uniq
      if (product.stock['internal'] <= product.low_stock_threshold && affected_stocks&.include?('internal')) ||
         (product.stock['external'] <= product.low_stock_threshold && affected_stocks&.include?('external'))
        NotificationCenter.call type: 'notify_admin_low_stock_threshold',
                                receiver: User.admins_and_managers,
                                attached_object: product
      end
      product
    end
  end
end
