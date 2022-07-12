# frozen_string_literal: true

# helpers for managing slots reservations (reservations for a time unit)
class SlotsReservationsService
  class << self
    def cancel(slot_reservation)
      # first we mark ths slot reseravtion as cancelled in DB, to free a ticket
      slot_reservation.update_attributes(canceled_at: DateTime.current)

      # then we try to remove this reservation from ElasticSearch, to keep the statistics up-to-date
      model_name = slot_reservation.reservation.reservable.class.name
      client = Elasticsearch::Model.client

      model = "Stats::#{model_name}".constantize
      client.delete_by_query(
        index: model.index_name,
        type: model.document_type,
        conflicts: 'proceed',
        body: { query: { match: { reservationId: slot_reservation.reservation_id } } }
      )
    end
  end
end
