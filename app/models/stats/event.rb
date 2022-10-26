# frozen_string_literal: true

# This is a statistical data saved in ElasticSearch, about an event reservation
class Stats::Event
  include Elasticsearch::Persistence::Model
  include StatConcern
  include StatReservationConcern

  attribute :eventId, Integer
  attribute :eventDate, String
  attribute :ageRange, String
  attribute :eventTheme, String
end
