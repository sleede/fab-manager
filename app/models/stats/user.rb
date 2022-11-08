# frozen_string_literal: true

# This is a statistical data saved in ElasticSearch, about revenue generated per user
class Stats::User
  include Elasticsearch::Persistence::Model
  include StatConcern
end
