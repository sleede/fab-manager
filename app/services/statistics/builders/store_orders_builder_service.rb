# frozen_string_literal: true

# Generate statistics indicators about store's orders
class Statistics::Builders::StoreOrdersBuilderService
  include Statistics::Concerns::HelpersConcern
  include Statistics::Concerns::StoreOrdersConcern

  class << self
    def build(options = default_options)
      # project list
      Statistics::FetcherService.store_orders_list(options).each do |o|
        Stats::StoreOrder.create({ date: format_date(o[:date]),
                                   type: 'order',
                                   subType: 'store',
                                   ca: o[:ca],
                                   products: o[:order_products],
                                   categories: o[:order_categories],
                                   stat: 1 }.merge(user_info_stat(o)))
      end
    end
  end
end
