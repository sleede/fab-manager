# frozen_string_literal: true

# helpers for managing slots reservations (reservations for a time unit)
class SlotsReservationsService
  class << self
    def cancel(slot_reservation)
      # first we mark ths slot reservation as cancelled in DB, to free a ticket
      slot_reservation.update(canceled_at: Time.current)

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
    rescue Faraday::ConnectionFailed
      warn 'Unable to update data in elasticsearch'
    end

    def validate(slot_reservation)
      if slot_reservation.update(is_valid: true)
        reservable = slot_reservation.reservation.reservable
        if reservable.is_a?(Event)
          reservable.update_nb_free_places
          reservable.save
        end
        NotificationCenter.call type: 'notify_member_reservation_validated',
                                receiver: slot_reservation.reservation.user,
                                attached_object: slot_reservation.reservation
        NotificationCenter.call type: 'notify_admin_reservation_validated',
                                receiver: User.admins_and_managers,
                                attached_object: slot_reservation.reservation
        return true
      end
      false
    end

    def invalidate(slot_reservation)
      if slot_reservation.update(is_valid: false)
        reservable = slot_reservation.reservation.reservable
        if reservable.is_a?(Event)
          reservable.update_nb_free_places
          reservable.save
        end
        return true
      end
      false
    end
  end
end
