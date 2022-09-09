# frozen_string_literal: true

# Provides methods for Product
class ProductService
  PRODUCTS_PER_PAGE = 12

  def self.list(filters)
    products = Product.includes(:product_images)
    if filters[:is_active].present?
      state = filters[:disabled] == 'false' ? [nil, false] : true
      products = products.where(is_active: state)
    end
    products = products.page(filters[:page]).per(PRODUCTS_PER_PAGE) if filters[:page].present?
    products
  end

  def self.pages(filters)
    products = Product.all
    if filters[:is_active].present?
      state = filters[:disabled] == 'false' ? [nil, false] : true
      products = Product.where(is_active: state)
    end
    products.page(1).per(PRODUCTS_PER_PAGE).total_pages
  end

  # amount params multiplied by hundred
  def self.amount_multiplied_by_hundred(amount)
    if amount.present?
      v = amount.to_f

      return nil if v.zero?

      return v * 100
    end
    nil
  end

  def self.update_stock(product, stock_type, reason, quantity, order_item_id = nil)
    remaining_stock = product.stock[stock_type] + quantity
    product.product_stock_movements.create(stock_type: stock_type, reason: reason, quantity: quantity, remaining_stock: remaining_stock,
                                           date: DateTime.current,
                                           order_item_id: order_item_id)
    product.stock[stock_type] = remaining_stock
    product.save
  end
end
