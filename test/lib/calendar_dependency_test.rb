# frozen_string_literal: true

require 'test_helper'
require 'fugit'
require 'icalendar'
require 'icalendar/tzinfo'

class CalendarDependencyTest < ActiveSupport::TestCase
  include WebMock::API

  test 'real reservation feeds and individual exports support all reservable types' do
    travel_to Time.utc(2010, 1, 1) do
      create_event_and_space_reservations
      %w[Machine Training Event Space].each do |type|
        calendar = ReservationCalendarService.new(reservable_type: type).call
        parsed = Icalendar::Calendar.parse(calendar.to_ical).first
        assert_not_empty parsed.events, type
        parsed.events.each do |event|
          assert event.uid.to_s.start_with?("#{type}-")
          assert event.dtstart.to_time < event.dtend.to_time
          assert_not_empty event.summary.to_s
        end
        reservation = Reservation.find_by!(reservable_type: type)
        individual = Icalendar::Calendar.parse(reservation.to_ics).first
        assert_not_empty individual.events, type
        assert_equal 'PRIVATE', individual.events.first.ip_class.to_s
        assert_equal 'DISPLAY', individual.events.first.alarms.first.action.to_s
      end
    end
  end

  test 'ICS text escaping Unicode and negative fractional offsets round trip' do
    calendar = Icalendar::Calendar.new
    summary = "Atelier, bois; Montréal\nBEGIN:VEVENT"
    calendar.event do |event|
      event.uid = 'synthetic-calendar@example.test'
      event.dtstart = Time.utc(2026, 11, 1, 13)
      event.dtend = Time.utc(2026, 11, 1, 14)
      event.summary = summary
      event.description = "line one\nline two, semicolon;"
      event.rrule = 'FREQ=DAILY;COUNT=3'
    end
    parsed = Icalendar::Calendar.parse(calendar.to_ical).first
    assert_equal 1, parsed.events.length
    assert_equal summary, parsed.events.first.summary.to_s
    assert_equal "line one\nline two, semicolon;", parsed.events.first.description.to_s
    assert_includes parsed.events.first.rrule.first.to_ical('RRULE'), 'COUNT=3'
    offset = Icalendar::Values::UtcOffset.new('-0330')
    assert_equal '-03:30', offset.to_s
    assert_equal '-0330', offset.value_ical
  end

  test 'generated VTIMEZONE transitions use the offset in effect before the change' do
    # RFC 5545 expresses DAYLIGHT/STANDARD onsets in local time at TZOFFSETFROM. iCalendar 2.7.1 emitted them
    # at TZOFFSETTO (for example 03:00 for the Paris spring change); 2.12.5 and later are correct.
    expected = {
      'Europe/Paris' => { daylight: ['020000', '+0100', '+0200'], standard: ['030000', '+0200', '+0100'] },
      'America/Toronto' => { daylight: ['020000', '-0500', '-0400'], standard: ['020000', '-0400', '-0500'] }
    }
    expected.each do |zone, changes|
      calendar = Icalendar::Calendar.new
      calendar.add_timezone TZInfo::Timezone.get(zone).ical_timezone(Time.utc(2026, 11, 1, 12))
      timezone = Icalendar::Calendar.parse(calendar.to_ical).first.timezones.first
      actual = { daylight: timezone.daylights.first, standard: timezone.standards.first }
      changes.each do |kind, (onset, from, to)|
        transition = actual.fetch(kind)
        assert_equal onset, transition.dtstart.strftime('%H%M%S'), "#{zone} #{kind} onset"
        assert_equal from, transition.tzoffsetfrom.value_ical, "#{zone} #{kind} offset from"
        assert_equal to, transition.tzoffsetto.value_ical, "#{zone} #{kind} offset to"
      end
    end
  end

  test 'the real calendar importer updates and deletes events from a stubbed feed' do
    source = i_calendars(:one)
    source.update!(url: 'https://calendar.example.test/feed.ics')
    calendar = Icalendar::Calendar.new
    calendar.event do |event|
      event.uid = 'synthetic-import@example.test'
      event.dtstart = Time.utc(2026, 11, 1, 13)
      event.dtend = Time.utc(2026, 11, 1, 14)
      event.summary = 'Réservation, Montréal'
      event.description = "first line\nsecond line"
    end
    stub_request(:get, source.url).to_return(body: calendar.to_ical, headers: { 'Content-Type' => 'text/calendar' })
    ICalendarImportService.new.import(source.id)
    imported = ICalendarEvent.find_by!(i_calendar_id: source.id, uid: 'synthetic-import@example.test')
    assert_equal 'Réservation, Montréal', imported.summary
    assert_equal Time.utc(2026, 11, 1, 13), imported.dtstart
    assert_equal "first line\nsecond line", imported.description

    stub_request(:get, source.url).to_return(body: Icalendar::Calendar.new.to_ical)
    ICalendarImportService.new.import(source.id)
    assert_not ICalendarEvent.exists?(id: imported.id)
  end

  test 'every actual rendered job schedule retains its next occurrences across DST references' do
    fixture = Rails.root.join('test/fixtures/files/dependencies/legacy_schedule.json')
    references = JSON.parse(File.read(fixture))
    Time.use_zone('America/Toronto') do
      references.each do |reference|
        travel_to Time.iso8601(reference.fetch('reference')) do
          actual = YAML.safe_load(ERB.new(File.read(Rails.root.join('config/schedule.yml'))).result)
          assert_equal reference.fetch('schedule'), actual
          actual.each do |name, config|
            { 'as_configured' => config.fetch('cron'),
              'America/Toronto' => "#{config.fetch('cron')} America/Toronto" }.each do |zone, expression|
              cron = Fugit::Cron.parse(expression)
              assert_not_nil cron, name
              current = Time.iso8601(reference.fetch('reference'))
              occurrences = Array.new(3) do
                current = cron.next_time(current).to_t
                current.utc.iso8601
              end
              assert_equal reference.fetch('occurrences').fetch(name).fetch(zone), occurrences, "#{name}: #{zone}"
            end
          end
        end
      end
    end
  end

  test 'daily Toronto cron retains local time across the spring and fall DST boundaries' do
    cron = Fugit::Cron.parse('0 9 * * * America/Toronto')
    spring = cron.next_time(Time.utc(2026, 3, 7, 0)).to_t
    spring_next = cron.next_time(spring).to_t
    assert_equal Time.utc(2026, 3, 7, 14), spring
    assert_equal Time.utc(2026, 3, 8, 13), spring_next
    assert_equal 23.hours, spring_next - spring
    fall = cron.next_time(Time.utc(2026, 10, 31, 0)).to_t
    fall_next = cron.next_time(fall).to_t
    assert_equal Time.utc(2026, 10, 31, 13), fall
    assert_equal Time.utc(2026, 11, 1, 14), fall_next
    assert_equal 25.hours, fall_next - fall
    assert_nil Fugit::Cron.parse('not a cron expression')
  end

  private

  def create_event_and_space_reservations
    Reservation.create!(reservable: events('event_1'), nb_reserve_places: 1,
                        statistic_profile: statistic_profiles(:pdurand),
                        slots_reservations_attributes: [{ slot_id: slots('slot_129').id }])
    availability = availabilities('availability_18')
    attributes = { availability: availability, start_at: availability.start_at, end_at: availability.start_at + 1.hour }
    slot = availability.slots.first || Slot.create!(attributes)
    Reservation.create!(reservable: spaces('space_1'), statistic_profile: statistic_profiles(:pdurand),
                        slots_reservations_attributes: [{ slot_id: slot.id }])
  end
end
