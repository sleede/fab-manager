module Stats
  class Event
    include Elasticsearch::Persistence::Model
    include StatConcern
    include StatReservationConcern

    attribute :eventId, Integer
    attribute :eventDate, String
    attribute :ageRange, String
    attribute :eventTheme, String
  end
end
