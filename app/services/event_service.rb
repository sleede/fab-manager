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
        start_at = Time.zone.local(start_date.year, start_date.month, start_date.day, 0, 0, 0)
        end_at = Time.zone.local(end_date.year, end_date.month, end_date.day, 23, 59, 59)
      else
        start_at = Time.zone.local(start_date.year, start_date.month, start_date.day, start_time.hour, start_time.min, start_time.sec)
        end_at = Time.zone.local(end_date.year, end_date.month, end_date.day, end_time.hour, end_time.min, end_time.sec)
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
        method = e.destroyable? ? :destroy : :soft_destroy!
        # we use double negation because destroy can return either a boolean (false) or an Event (in case of delete success)
        results.push status: !!e.send(method), event: e # rubocop:disable Style/DoubleNegation
      end
      results
    end
  end
end
