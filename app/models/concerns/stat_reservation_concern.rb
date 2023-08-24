# frozen_string_literal: true

# Defines the reservation statistics data model
module StatReservationConcern
  extend ActiveSupport::Concern

  included do
    attribute :reservationId, Integer
    attribute :reservationContextId, Integer
    attribute :ca, Float
    attribute :name, String
  end
end
