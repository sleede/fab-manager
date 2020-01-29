# frozen_string_literal: true

# Provides helper methods for Events resources and properties
class EventService
  def self.process_params(params)
    # handle dates & times (whole-day events or not, maybe during many days)
    range = EventService.date_range({ date: params[:start_date], time: params[:start_time] },
                                    { date: params[:end_date], time: params[:end_time] },
                                    params[:all_day] == 'true')
    params.merge!(availability_attributes: { id: params[:availability_id],
                                             start_at: range[:start_at],
                                             end_at: range[:end_at],
                                             available_type: 'event' })
          .except!(:start_date, :end_date, :start_time, :end_time, :all_day)
    # convert main price to centimes
    params[:amount] = (params[:amount].to_f * 100 if params[:amount].present?)
    # delete non-complete "other" prices and convert them to centimes
    unless params[:event_price_categories_attributes].nil?
      params[:event_price_categories_attributes].delete_if do |price_cat|
        price_cat[:price_category_id].empty? || price_cat[:amount].empty?
      end
      params[:event_price_categories_attributes].each do |price_cat|
        price_cat[:amount] = price_cat[:amount].to_f * 100
      end
    end
    # return the resulting params object
    params
  end

  def self.date_range(starting, ending, all_day)
    start_date = Time.zone.parse(starting[:date])
    end_date = Time.zone.parse(ending[:date])
    start_time = Time.parse(starting[:time]) if starting[:time]
    end_time = Time.parse(ending[:time]) if ending[:time]
    if all_day
      start_at = DateTime.new(start_date.year, start_date.month, start_date.day, 0, 0, 0, start_date.zone)
      end_at = DateTime.new(end_date.year, end_date.month, end_date.day, 23, 59, 59, end_date.zone)
    else
      start_at = DateTime.new(start_date.year, start_date.month, start_date.day, start_time.hour, start_time.min, start_time.sec, start_date.zone)
      end_at = DateTime.new(end_date.year, end_date.month, end_date.day, end_time.hour, end_time.min, end_time.sec, end_date.zone)
    end
    { start_at: start_at, end_at: end_at }
  end

  # delete one or more events (if periodic)
  def self.delete(event_id, mode = 'single')
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
               Event.where(
                 'recurrence_id = ?',
                 event.recurrence_id
               )
             else
               []
             end

    events.each do |e|
      # here we use double negation because safe_destroy can return either a boolean (false) or an Availability (in case of delete success)
      results.push status: !!e.safe_destroy, event: e # rubocop:disable Style/DoubleNegation
    end
    results
  end

  # update one or more events (if periodic)
  def self.update(event, event_params, mode = 'single')
    results = []
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
                 .where(
                   'recurrence_id = ?',
                   event.recurrence_id
                 )
             else
               []
             end

    events.each do |e|
      next unless e.id != event.id

      start_at = event_params['availability_attributes']['start_at']
      end_at = event_params['availability_attributes']['end_at']
      event_price_categories_attributes = event_params['event_price_categories_attributes']
      event_files_attributes = event_params['event_files_attributes']
      e_params = event_params.merge(
        availability_id: e.availability_id,
        availability_attributes: {
          id: e.availability_id,
          start_at: e.availability.start_at.change(hour: start_at.hour, min: start_at.min),
          end_at: e.availability.end_at.change(hour: end_at.hour, min: end_at.min),
          available_type: e.availability.available_type
        }
      )
      epc_attributes = []
      event_price_categories_attributes&.each do |epca|
        epc = e.event_price_categories.find_by(price_category_id: epca['price_category_id'])
        if epc
          epc_attributes.push(
            id: epc.id,
            price_category_id: epc.price_category_id,
            amount: epca['amount'],
            _destroy: epca['_destroy']
          )
        else
          event_price = event.event_price_categories.find(epca['id'])
          epc_attributes.push(
            price_category_id: epca['price_category_id'],
            amount: event_price.amount,
            _destroy: ''
          )
        end
      end
      unless epc_attributes.empty?
        e_params = e_params.merge(
          event_price_categories_attributes: epc_attributes
        )
      end

      ef_attributes = []
      event_files_attributes&.each do |efa|
        if efa['id'].present?
          event_file = event.event_files.find(efa['id'])
          ef = e.event_files.find_by(attachment: event_file.attachment.file.filename)
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
      unless ef_attributes.empty?
        e_params = e_params.merge(
          event_files_attributes: ef_attributes
        )
      end
      results.push status: !!e.update(e_params.permit!), event: e # rubocop:disable Style/DoubleNegation
    end
    results.push status: !!event.update(event_params), event: event # rubocop:disable Style/DoubleNegation
    results
  end
end
