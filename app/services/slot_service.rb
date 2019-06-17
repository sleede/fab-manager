# frozen_string_literal: true

# helpers for managing slots (reservations sub-units)
class SlotService
  def cancel(slot)
    # first we mark ths slot as cancelled in DB, to free a ticket
    slot.update_attributes(canceled_at: DateTime.now)

    # then we try to remove this reservation from ElasticSearch, to keep the statistics up-to-date
    model_name = slot.reservation.reservable.class.name
    client = Elasticsearch::Model.client

    model = "Stats::#{model_name}".constantize
    client.delete_by_query(
      index: model.index_name,
      type: model.document_type,
      conflicts: 'proceed',
      body: { query: { match: { reservationId: slot.reservation.id } } }
    )
  end
end
