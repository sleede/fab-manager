# frozen_string_literal: true

# This is a statistical data saved in ElasticSearch, about a subscription to a plan
class Stats::Subscription
  include Elasticsearch::Persistence::Model
  include StatConcern

  attribute :ca, Float
  attribute :planId, Integer
  attribute :subscriptionId, Integer
  attribute :invoiceItemId, Integer
  attribute :groupName, String
  attribute :coupon, String
end
