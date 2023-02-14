# frozen_string_literal: true

# Provides helper methods to create new Events and its recurring occurrences
class Event::CreateEventService
  extend ApplicationHelper

  class << self
    def create_occurence(event, date)
      service = Availabilities::CreateAvailabilitiesService.new
      occurrence = Event.new(
        recurrence: 'none',
        title: event.title,
        description: event.description,
        event_image: occurrence_image(event),
        event_files: occurrence_files(event),
        availability: Availability.new(start_at: occurence_start_date(event, date),
                                       end_at: occurrence_end_date(event, date),
                                       available_type: 'event'),
        availability_id: nil,
        category_id: event.category_id,
        age_range_id: event.age_range_id,
        event_themes: event.event_themes,
        amount: event.amount,
        event_price_categories: occurrence_price_categories(event),
        nb_total_places: event.nb_total_places,
        recurrence_id: event.id,
        advanced_accounting: occurrence_advanced_accounting(event)
      )
      occurrence.save
      service.create_slots(occurrence.availability)
    end

    private

    def occurence_start_date(event, date)
      Time.zone.local(date.year, date.month, date.day,
                      event.availability.start_at.hour, event.availability.start_at.min, event.availability.start_at.sec)
    end

    def occurrence_end_date(event, date)
      days_diff = event.availability.end_at.day - event.availability.start_at.day
      end_date = date + days_diff.days
      Time.zone.local(end_date.year, end_date.month, end_date.day,
                      event.availability.end_at.hour, event.availability.end_at.min, event.availability.end_at.sec)
    end

    def occurrence_image(event)
      EventImage.new(attachment: event.event_image.attachment) if event.event_image
    end

    def occurrence_files(event)
      event.event_files.map do |f|
        EventFile.new(attachment: f.attachment)
      end
    end

    def occurrence_price_categories(event)
      event.event_price_categories.map do |epc|
        EventPriceCategory.new(price_category_id: epc.price_category_id, amount: epc.amount)
      end
    end

    def occurrence_advanced_accounting(event)
      AdvancedAccounting.new(code: event.advanced_accounting&.code, analytical_section: event.advanced_accounting&.analytical_section)
    end
  end
end
