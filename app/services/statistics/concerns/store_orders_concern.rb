# frozen_string_literal: true

# Provides methods to consolidate data from Store Orders to use in statistics
module Statistics::Concerns::StoreOrdersConcern
  extend ActiveSupport::Concern

  class_methods do
    def get_order_products(order)
      order.order_items.where(orderable_type: 'Product').map do |item|
        { id: item.orderable_id, name: item.orderable.name }
      end
    end

    def get_order_categories(order)
      order.order_items
           .where(orderable_type: 'Product')
           .map(&:orderable)
           .map(&:product_category)
           .compact
           .map { |cat| { id: cat.id, name: cat.name } }
           .uniq
    end

    def store_order_info(order)
      {
        order_id: order.id,
        order_state: order.state,
        order_products: get_order_products(order),
        order_categories: get_order_categories(order)
      }
    end
  end
end
