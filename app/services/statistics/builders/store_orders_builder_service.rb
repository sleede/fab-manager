# frozen_string_literal: true

# Generate statistics indicators about store's orders
class Statistics::Builders::StoreOrdersBuilderService
  include Statistics::Concerns::HelpersConcern
  include Statistics::Concerns::StoreOrdersConcern

  class << self
    def build(options = default_options)
      states = {
        'paid-processed': %w[paid in_progress ready delivered],
        aborted: %w[payment_failed refunded canceled]
      }
      # orders list
      states.each do |sub_type, order_states|
        Statistics::FetcherService.each_store_order(order_states, options) do |o|
          Stats::Order.create({ date: format_date(o[:date]),
                                type: 'store',
                                subType: sub_type,
                                ca: o[:ca],
                                products: o[:order_products],
                                categories: o[:order_categories],
                                orderId: o[:order_id],
                                state: o[:order_state],
                                coupon: o[:coupon],
                                groupName: o[:groupName],
                                stat: 1 }.merge(user_info_stat(o)))
        end
      end
    end
  end
end
