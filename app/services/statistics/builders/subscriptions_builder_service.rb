# frozen_string_literal: true

# Generate statistics indicators about subscriptions
class Statistics::Builders::SubscriptionsBuilderService
  include Statistics::Concerns::HelpersConcern

  class << self
    def build(options = default_options)
      # subscription list
      Statistics::FetcherService.subscriptions_list(options).each do |s|
        SearchIndex.create_stat(family: 'subscription', attributes: { date: format_date(s[:date]),
                                                                      type: s[:duration],
                                                                      subType: s[:slug],
                                                                      stat: 1,
                                                                      ca: s[:ca],
                                                                      planId: s[:plan_id],
                                                                      subscriptionId: s[:subscription_id],
                                                                      invoiceItemId: s[:invoice_item_id],
                                                                      coupon: s[:coupon],
                                                                      groupName: s[:plan_group_name] }.merge(user_info_stat(s)))
      end
    end
  end
end
