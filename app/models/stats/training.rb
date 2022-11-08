# frozen_string_literal: true

# This is a statistical data saved in ElasticSearch, about a training reservation
class Stats::Training
  include Elasticsearch::Persistence::Model
  include StatConcern
  include StatReservationConcern

  attribute :trainingId, Integer
  attribute :trainingDate, String
end
