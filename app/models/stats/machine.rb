# frozen_string_literal: true

# This is a statistical data saved in ElasticSearch, about a machine reservation
class Stats::Machine < Stats::Base
  include StatConcern
  include StatReservationConcern

  attribute :machineId, Integer
  attribute :machineDates, Array
end
