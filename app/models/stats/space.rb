# frozen_string_literal: true

# This is a statistical data saved in ElasticSearch, about a space reservation
class Stats::Space
  include Elasticsearch::Persistence::Model
  include StatConcern
  include StatReservationConcern

  attribute :spaceId, Integer
  attribute :spaceDates, Array
end
