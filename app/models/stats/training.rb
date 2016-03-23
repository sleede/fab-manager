module Stats
  class Training
    include Elasticsearch::Persistence::Model
    include StatConcern
    include StatReservationConcern

    attribute :trainingId, Integer
    attribute :trainingDate, String
  end
end
