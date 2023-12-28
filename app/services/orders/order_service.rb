# frozen_string_literal: true

# Provides methods for Order
class Orders::OrderService
  class << self
    include ApplicationHelper

    ORDERS_PER_PAGE = 20

    def list(filters, current_user)
      orders = Order.includes(statistic_profile: [user: [:profile]]).where(nil)
      orders = filter_by_user(orders, filters, current_user)
      orders = filter_by_reference(orders, filters, current_user)
      orders = filter_by_state(orders, filters)
      orders = filter_by_period(orders, filters)

      orders = orders.where.not(state: 'cart') if current_user.member?
      orders = orders_ordering(orders, filters)
      total_count = orders.count
      orders = orders.page(filters[:page] || 1).per(ORDERS_PER_PAGE)
      {
        data: orders,
        page: filters[:page]&.to_i || 1,
        total_pages: orders.page(1).per(ORDERS_PER_PAGE).total_pages,
        page_size: ORDERS_PER_PAGE,
        total_count: total_count
      }
    end

    def update_state(order, current_user, state, note = nil)
      case state
      when 'in_progress'
        ::Orders::SetInProgressService.new.call(order, current_user)
      when 'ready'
        ::Orders::OrderReadyService.new.call(order, current_user, note)
      when 'canceled'
        ::Orders::OrderCanceledService.new.call(order, current_user)
      when 'delivered'
        ::Orders::OrderDeliveredService.new.call(order, current_user)
      when 'refunded'
        ::Orders::OrderRefundedService.new.call(order, current_user)
      else
        nil
      end

      # update in elasticsearch (statistics)
      stat_order = Stats::Order.search(query: { term: { orderId: order.id } })
      sub_type = if state.in?(%w[paid in_progress ready delivered])
                   'paid-processed'
                 elsif state.in?(%w[payment_failed refunded canceled])
                   'aborted'
                 end

      stat_order.map { |s| s.update(subType: sub_type, state: state) } if sub_type.present?

      order
    end

    def in_stock?(order, stock_type = 'external')
      order.order_items.each do |item|
        return false if item.orderable.stock[stock_type] < item.quantity || item.orderable.stock[stock_type] < item.orderable.quantity_min
      end
      true
    end

    def greater_than_quantity_min?(order)
      order.order_items.each do |item|
        return false if item.quantity < item.orderable.quantity_min
      end
      true
    end

    def item_amount_not_equal?(order)
      order.order_items.each do |item|
        orderable_amount = item.orderable.amount || 0
        return false if item.amount != orderable_amount
      end
      true
    end

    def all_products_is_active?(order)
      order.order_items.each do |item|
        return false unless item.orderable.is_active
      end
      true
    end

    def withdrawal_instructions(order)
      res = order&.order_activities&.find_by(activity_type: 'ready')&.note.presence ||
            Setting.get('store_withdrawal_instructions').presence ||
            _t('order.please_contact_FABLAB', FABLAB: Setting.get('fablab_name').presence || 'empty')

      ActionController::Base.helpers.sanitize(res, tags: %w[p ul li h3 u em strong a], attributes: %w[target rel href])
    end

    private

    def filter_by_user(orders, filters, current_user)
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
      orders
    end

    def filter_by_reference(orders, filters, current_user)
      return orders unless filters[:reference].present? && current_user.privileged?

      orders.where(reference: filters[:reference])
    end

    def filter_by_state(orders, filters)
      return orders if filters[:states].blank?

      state = filters[:states].split(',')
      orders.where(state: state) unless state.empty?
    end

    def filter_by_period(orders, filters)
      return orders unless filters[:period_from].present? && filters[:period_to].present?

      orders.where(created_at: Date.parse(filters[:period_from]).in_time_zone..Date.parse(filters[:period_to]).in_time_zone.end_of_day)
    end

    def orders_ordering(orders, filters)
      key, order = filters[:sort]&.split('-')
      key ||= 'created_at'
      order ||= 'desc'

      orders.order(key => order)
    end
  end
end
