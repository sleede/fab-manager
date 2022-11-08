# frozen_string_literal: true

# This is a statistical data saved in ElasticSearch, about an account creation
class Stats::Account
  include Elasticsearch::Persistence::Model
  include StatConcern
end
