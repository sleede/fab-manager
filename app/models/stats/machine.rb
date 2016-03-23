module Stats
  class Machine
    include Elasticsearch::Persistence::Model
    include StatConcern
    include StatReservationConcern

    attribute :machineId, Integer
  end
end
