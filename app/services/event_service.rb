# frozen_string_literal: true

require './app/helpers/application_helper'

# Provides helper methods for Events resources and properties
class EventService
  class << self
    include ApplicationHelper

    def process_params(params)
      # handle dates & times (whole-day events or not, maybe during many days)
      range = EventService.date_range({ date: params[:start_date], time: params[:start_time] },
                                      { date: params[:end_date], time: params[:end_time] },
                                      params[:all_day] == 'true')
      params.merge!(availability_attributes: { id: params[:availability_id],
                                               start_at: range[:start_at],
                                               end_at: range[:end_at],
                                               available_type: 'event' })
            .extract!(:start_date, :end_date, :start_time, :end_time, :all_day)
      # convert main price to centimes
      params[:amount] = to_centimes(params[:amount]) if params[:amount].present?
      # delete non-complete "other" prices and convert them to centimes
      unless params[:event_price_categories_attributes].nil?
        params[:event_price_categories_attributes].delete_if do |price_cat|
          price_cat[:price_category_id].empty? || price_cat[:amount].empty?
        end
        params[:event_price_categories_attributes].each do |price_cat|
          price_cat[:amount] = to_centimes(price_cat[:amount])
        end
      end
      # return the resulting params object
      params
    end

    def date_range(starting, ending, all_day)
      start_date = Time.zone.parse(starting[:date])
      end_date = Time.zone.parse(ending[:date])
      start_time = starting[:time] ? Time.zone.parse(starting[:time]) : nil
      end_time = ending[:time] ? Time.zone.parse(ending[:time]) : nil
      if all_day || start_time.nil? || end_time.nil?
        start_at = DateTime.new(start_date.year, start_date.month, start_date.day, 0, 0, 0, start_date.zone)
        end_at = DateTime.new(end_date.year, end_date.month, end_date.day, 23, 59, 59, end_date.zone)
      else
        start_at = DateTime.new(start_date.year, start_date.month, start_date.day, start_time.hour, start_time.min, start_time.sec,
                                start_date.zone)
        end_at = DateTime.new(end_date.year, end_date.month, end_date.day, end_time.hour, end_time.min, end_time.sec, end_date.zone)
      end
      { start_at: start_at, end_at: end_at }
    end

    # delete one or more events (if periodic)
    def delete(event_id, mode = 'single')
      results = []
      event = Event.find(event_id)
      events = case mode
               when 'single'
                 [event]
               when 'next'
                 Event.includes(:availability)
                      .where(
                        'availabilities.start_at >= ? AND events.recurrence_id = ?',
                        event.availability.start_at,
                        event.recurrence_id
                      )
                      .references(:availabilities, :events)
               when 'all'
                 Event.where(recurrence_id: event.recurrence_id)
               else
                 []
               end

      events.each do |e|
        # we use double negation because safe_destroy can return either a boolean (false) or an Availability (in case of delete success)
        results.push status: !!e.safe_destroy, event: e # rubocop:disable Style/DoubleNegation
      end
      results
    end

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

      ef_attributes = file_attributes(base_event, occurrence, event_params)
      e_params.merge(
        event_files_attributes: ef_attributes
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
      event_params['event_files_attributes']&.each do |efa|
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
  end
end
