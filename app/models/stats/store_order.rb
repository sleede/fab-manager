# frozen_string_literal: true

class Stats::StoreOrder
  include Elasticsearch::Persistence::Model
  include StatConcern

  attribute :orderId, Integer
  attribute :state, String
  attribute :products, Array
  attribute :categories, Array
  attribute :ca, Float
end
