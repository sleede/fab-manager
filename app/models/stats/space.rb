module Stats
  class Space
    include Elasticsearch::Persistence::Model
    include StatConcern
    include StatReservationConcern

    attribute :spaceId, Integer
  end
end
