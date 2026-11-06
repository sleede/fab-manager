# frozen_string_literal: true

# This is a statistical data saved in ElasticSearch, about a training reservation
class Stats::Training < Stats::Base
  include StatConcern
  include StatReservationConcern

  attribute :trainingId, Integer
  attribute :trainingDate, String
end
