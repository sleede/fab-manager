module Stats
  class Subscription
    include Elasticsearch::Persistence::Model
    include StatConcern

    attribute :ca, Float
    attribute :planId, Integer
    attribute :subscriptionId, Integer
    attribute :invoiceItemId, Integer
    attribute :groupName, String
  end
end
