# frozen_string_literal: true

# Provides helper methods to update existing Events and their recurring occurrences
class Event::UpdateEventService
  class << self
    # update one or more events (if periodic)
    def update(event, event_params, mode = 'single')
      events = case mode
               when 'single'
                 [event]
               when 'next'
                 Event.includes(:availability, :event_price_categories, :event_files)
                      .where(
                        'availabilities.start_at >= ? AND events.recurrence_id = ?',
                        event.availability.start_at,
                        event.recurrence_id
                      )
                      .references(:availabilities, :events)
               when 'all'
                 Event.includes(:availability, :event_price_categories, :event_files)
                      .where(recurrence_id: event.recurrence_id)
               else
                 []
               end
      update_occurrences(event, events, event_params)
    end

    private

    def update_occurrences(base_event, occurrences, event_params)
      results = {
        events: [],
        slots: []
      }
      original_slots_ids = base_event.availability.slots.map(&:id)

      occurrences.each do |occurrence|
        next unless occurrence.id != base_event.id

        e_params = occurrence_params(base_event, occurrence, event_params)
        begin
          results[:events].push status: !!occurrence.update(e_params.permit!), event: occurrence # rubocop:disable Style/DoubleNegation
        rescue StandardError => e
          results[:events].push status: false, event: occurrence, error: e.try(:record).try(:class).try(:name), message: e.message
        end
        results[:slots].concat(update_slots(occurrence.availability_id, original_slots_ids))
      end

      begin
        event_params[:availability_attributes][:id] = base_event.availability_id
        results[:events].push status: !!base_event.update(event_params), event: base_event # rubocop:disable Style/DoubleNegation
      rescue StandardError => e
        results[:events].push status: false, event: base_event, error: e.try(:record).try(:class).try(:name), message: e.message
      end
      results[:slots].concat(update_slots(base_event.availability_id, original_slots_ids))
      results
    end

    def update_slots(availability_id, original_slots_ids)
      results = []
      avail = Availability.find(availability_id)
      Slot.where(id: original_slots_ids).each do |slot|
        results.push(
          status: !!slot.update(availability_id: availability_id, start_at: avail.start_at, end_at: avail.end_at), # rubocop:disable Style/DoubleNegation
          slot: slot
        )
      rescue StandardError => e
        results.push status: false, slot: s, error: e.try(:record).try(:class).try(:name), message: e.message
      end
      results
    end

    def occurrence_params(base_event, occurrence, event_params)
      start_at = event_params['availability_attributes']['start_at']
      end_at = event_params['availability_attributes']['end_at']
      e_params = event_params.merge(
        availability_id: occurrence.availability_id,
        availability_attributes: {
          id: occurrence.availability_id,
          start_at: occurrence.availability.start_at.change(hour: start_at.hour, min: start_at.min),
          end_at: occurrence.availability.end_at.change(hour: end_at.hour, min: end_at.min),
          available_type: occurrence.availability.available_type
        }
      )
      epc_attributes = price_categories_attributes(base_event, occurrence, event_params)
      unless epc_attributes.empty?
        e_params = e_params.merge(
          event_price_categories_attributes: epc_attributes
        )
      end

      e_params.merge(
        event_files_attributes: file_attributes(base_event, occurrence, event_params),
        event_image_attributes: image_attributes(occurrence, event_params)
      )
    end

    def price_categories_attributes(base_event, occurrence, event_params)
      epc_attributes = []
      event_params['event_price_categories_attributes']&.each do |epca|
        epc = occurrence.event_price_categories.find_by(price_category_id: epca['price_category_id'])
        if epc
          epc_attributes.push(
            id: epc.id,
            price_category_id: epc.price_category_id,
            amount: epca['amount'],
            _destroy: epca['_destroy']
          )
        elsif epca['id'].present?
          event_price = base_event.event_price_categories.find(epca['id'])
          epc_attributes.push(
            price_category_id: epca['price_category_id'],
            amount: event_price.amount,
            _destroy: ''
          )
        end
      end
      epc_attributes
    end

    def file_attributes(base_event, occurrence, event_params)
      ef_attributes = []
      event_params['event_files_attributes']&.values&.each do |efa|
        if efa['id'].present?
          event_file = base_event.event_files.find(efa['id'])
          ef = occurrence.event_files.find_by(attachment: event_file.attachment.file.filename)
          if ef
            ef_attributes.push(
              id: ef.id,
              attachment: efa['attachment'],
              _destroy: efa['_destroy']
            )
          end
        else
          ef_attributes.push(efa)
        end
      end
      ef_attributes
    end

    # @param occurrence [Event]
    # @param event_params [ActionController::Parameters]
    def image_attributes(occurrence, event_params)
      if event_params['event_image_attributes'].nil? || event_params['event_image_attributes']['id'].present?
        { id: occurrence.event_image&.id }
      else
        event_params['event_image_attributes']
      end
    end
  end
end
