module StatReservationConcern
  extend ActiveSupport::Concern

  included do
    attribute :reservationId, Integer
    attribute :ca, Float
    attribute :name, String
  end
end
