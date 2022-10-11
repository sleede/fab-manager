# frozen_string_literal: true

# This is a statistical data saved in ElasticSearch, about a store's order
class Stats::Order
  include Elasticsearch::Persistence::Model
  include StatConcern

  attribute :orderId, Integer
  attribute :state, String
  attribute :products, Array
  attribute :categories, Array
  attribute :ca, Float
end
