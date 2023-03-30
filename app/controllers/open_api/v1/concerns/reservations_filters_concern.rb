# frozen_string_literal: true

# Filter the list of reservations by the given parameters
module OpenAPI::V1::Concerns::ReservationsFiltersConcern
  extend ActiveSupport::Concern

  included do
    # @param reservations [ActiveRecord::Relation<Reservation>]
    # @param filters [ActionController::Parameters]
    def filter_by_after(reservations, filters)
      return reservations if filters[:after].blank?

      reservations.where('reservations.created_at >= ?', Time.zone.parse(filters[:after]))
    end

    # @param reservations [ActiveRecord::Relation<Reservation>]
    # @param filters [ActionController::Parameters]
    def filter_by_before(reservations, filters)
      return reservations if filters[:before].blank?

      reservations.where('reservations.created_at <= ?', Time.zone.parse(filters[:before]))
    end

    # @param reservations [ActiveRecord::Relation<Reservation>]
    # @param filters [ActionController::Parameters]
    def filter_by_user(reservations, filters)
      return reservations if filters[:user_id].blank?

      reservations.where(statistic_profiles: { user_id: may_array(filters[:user_id]) })
    end

    # @param reservations [ActiveRecord::Relation<Reservation>]
    # @param filters [ActionController::Parameters]
    def filter_by_reservable_type(reservations, filters)
      return reservations if filters[:reservable_type].blank?

      reservations.where(reservable_type: format_type(filters[:reservable_type]))
    end

    # @param reservations [ActiveRecord::Relation<Reservation>]
    # @param filters [ActionController::Parameters]
    def filter_by_reservable_id(reservations, filters)
      return reservations if filters[:reservable_id].blank?

      reservations.where(reservable_id: may_array(filters[:reservable_id]))
    end

    # @param reservations [ActiveRecord::Relation<Reservation>]
    # @param filters [ActionController::Parameters]
    def filter_by_availability_id(reservations, filters)
      return reservations if filters[:availability_id].blank?

      reservations.joins(:slots_reservations, :slots)
                  .where(slots_reservations: { slots: { availability_id: may_array(filters[:availability_id]) } })
    end

    # @param type [String]
    def format_type(type)
      type.singularize.classify
    end
  end
end
