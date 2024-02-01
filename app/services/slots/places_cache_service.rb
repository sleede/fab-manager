# frozen_string_literal: true

# Services around slots
module Slots; end

# Maintain the cache of reserved places for a slot
class Slots::PlacesCacheService
  class << self
    # @param slot [Slot]
    def refresh(slot)
      return if slot.nil?

      reservables = case slot.availability.available_type
                    when 'machines'
                      slot.availability.machines
                    when 'training'
                      slot.availability.trainings
                    when 'space'
                      slot.availability.spaces
                    when 'event'
                      Event.where(id: slot.availability.event.id)
                    else
                      Rails.logger.warn "[Slots::PlacesCacheService#update] Availability #{slot.availability_id} with unknown " \
                                        "type #{slot.availability.available_type}"
                      [nil]
                    end
      browser = reservables.respond_to?(:find_each) ? :find_each : :each
      places = []
      reservables.try(browser) do |reservable|
        reservations = Slots::ReservationsService.reservations(slot.slots_reservations, [reservable])
        pending = Slots::ReservationsService.pending_reservations(slot.cart_item_reservation_slots.map(&:id), [reservable])

        reserved_places = (reservations[:reservations].count || 0) + (pending[:reservations].count || 0)
        if slot.availability.available_type == 'event'
          reserved_places = if slot.availability.event.nb_total_places.nil?
                              0
                            else
                              slot.availability.event.nb_total_places - slot.availability.event.nb_free_places
                            end
        end
        places.push({
                      reservable_type: reservable.class.name,
                      reservable_id: reservable.try(&:id),
                      reserved_places: reserved_places,
                      user_ids: reservations[:user_ids] + pending[:user_ids]
                    })
      end
      slot.update(places: places)
    end

    # @param slot [Slot]
    # @param reservable_type [String]
    # @param reservable_id [Number]
    # @param places [Number]
    # @param operation [Symbol] :+ OR :-
    def change_places(slot, reservable_type, reservable_id, places, operation = :+)
      return if slot.nil?

      ActiveRecord::Base.connection.execute <<-SQL.squish
        with reservable_places as (
          select ('{'||index-1||',reserved_places}')::text[] as path
                ,(place->>'reserved_places')::decimal as reserved_places
            from slots
                ,jsonb_array_elements(places) with ordinality arr(place, index)
           where place->>'reservable_type' = '#{reservable_type}'
             and place->>'reservable_id' = '#{reservable_id}'
             and id = #{slot.id}
        )
        update slots
           set places = jsonb_set(places, reservable_places.path, (reservable_places.reserved_places #{operation} #{places})::varchar::jsonb, true)
          from reservable_places
         where id = #{slot.id};
      SQL
    end

    # @param slot [Slot]
    # @param reservable_type [String]
    # @param reservable_id [Number]
    # @param user_ids [Array<Number>]
    def remove_users(slot, reservable_type, reservable_id, user_ids)
      return if slot.nil? || user_ids.compact.empty?

      ActiveRecord::Base.connection.execute <<-SQL.squish
        with users as (
          select ('{'||index-1||',user_ids}')::text[] as path
                ,place->>'user_ids' as user_ids
            from slots
                ,jsonb_array_elements(places) with ordinality arr(place, index)
           where place->>'reservable_type' = '#{reservable_type}'
             and place->>'reservable_id' = '#{reservable_id}'
             and id = #{slot.id}
        ),
        all_users as (
          select (ids.id)::text::int as all_ids
            from users
                ,jsonb_array_elements(users.user_ids::jsonb) with ordinality ids(id, index)
        ),
        remaining_users as (
           SELECT array_to_json(array(SELECT unnest(array_agg(all_users.all_ids)) EXCEPT SELECT unnest('{#{user_ids.to_s.gsub(/\]| |\[|/, '')}}'::int[])))::jsonb as ids
             from all_users
        )
        update slots
           set places = jsonb_set(places, users.path, remaining_users.ids, false)
          from users, remaining_users
         where id = #{slot.id};
      SQL
    end

    # @param slot [Slot]
    # @param reservable_type [String]
    # @param reservable_id [Number]
    # @param user_ids [Array<Number>]
    def add_users(slot, reservable_type, reservable_id, user_ids)
      return if slot.nil?

      ActiveRecord::Base.connection.execute <<-SQL.squish
        with users as (
          select ('{'||index-1||',user_ids}')::text[] as path
                ,place->>'user_ids' as user_ids
            from slots
                ,jsonb_array_elements(places) with ordinality arr(place, index)
           where place->>'reservable_type' = '#{reservable_type}'
             and place->>'reservable_id' = '#{reservable_id}'
             and id = #{slot.id}
        ),
        all_users as (
          select (ids.id)::text::int as all_ids
            from users
                ,jsonb_array_elements(users.user_ids::jsonb) with ordinality ids(id, index)
        ),
        new_users as (
           SELECT array_to_json(array_cat(array_agg(all_users.all_ids), '{#{user_ids.to_s.gsub(/\]| |\[|/, '')}}'::int[]))::jsonb as ids
             from all_users
        )
        update slots
           set places = jsonb_set(places, users.path, new_users.ids, false)
          from users, new_users
         where id = #{slot.id};
      SQL
    end
  end
end
