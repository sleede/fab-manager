# frozen_string_literal: true

# Provides methods for Order
class Orders::OrderService
  ORDERS_PER_PAGE = 20

  def self.list(filters, current_user)
    orders = Order.where(nil)
    if filters[:user_id]
      statistic_profile_id = current_user.statistic_profile.id
      if (current_user.member? && current_user.id == filters[:user_id].to_i) || current_user.privileged?
        user = User.find(filters[:user_id])
        statistic_profile_id = user.statistic_profile.id
      end
      orders = orders.where(statistic_profile_id: statistic_profile_id)
    elsif current_user.member?
      orders = orders.where(statistic_profile_id: current_user.statistic_profile.id)
    else
      orders = orders.where.not(statistic_profile_id: nil)
    end

    orders = orders.where(reference: filters[:reference]) if filters[:reference].present? && current_user.privileged?

    if filters[:states].present?
      state = filters[:states].split(',')
      orders = orders.where(state: state) unless state.empty?
    end

    if filters[:period_from].present? && filters[:period_to].present?
      orders = orders.where(created_at: DateTime.parse(filters[:period_from])..DateTime.parse(filters[:period_to]).end_of_day)
    end

    orders = orders.where.not(state: 'cart') if current_user.member?
    orders = orders.order(created_at: filters[:sort] || 'DESC')
    total_count = orders.count
    orders = orders.page(filters[:page] || 1).per(ORDERS_PER_PAGE)
    {
      data: orders,
      page: filters[:page] || 1,
      total_pages: orders.page(1).per(ORDERS_PER_PAGE).total_pages,
      page_size: ORDERS_PER_PAGE,
      total_count: total_count
    }
  end

  def in_stock?(order, stock_type = 'external')
    order.order_items.each do |item|
      return false if item.orderable.stock[stock_type] < item.quantity
    end
    true
  end

  def all_products_is_active?(order)
    order.order_items.each do |item|
      return false unless item.orderable.is_active
    end
    true
  end
end
