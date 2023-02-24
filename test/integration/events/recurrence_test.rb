# frozen_string_literal: true

require 'test_helper'

module Events; end

class Events::RecurrenceTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'create a recurrent event' do
    name = 'Make your skatebord'
    post '/api/events',
         params: {
           event: {
             title: name,
             event_image_attributes: {
               attachment: fixture_file_upload('event/Skateboard.jpg')
             },
             description: 'Come make you own skatebord from stratch...',
             start_date: 1.week.from_now.utc,
             end_date: 1.week.from_now.utc,
             all_day: true,
             amount: 20,
             event_theme_ids: [1],
             category_id: 2,
             age_range_id: 1,
             recurrence: 'week',
             recurrence_end_at: 10.weeks.from_now.utc,
             event_files_attributes: [
               { attachment: fixture_file_upload('document.pdf', 'application/pdf', true) },
               { attachment: fixture_file_upload('document2.pdf', 'application/pdf', true) }
             ],
             event_price_categories_attributes: [
               { price_category_id: 1, amount: 10 },
               { price_category_id: 2, amount: 15 }
             ],
             advanced_accounting_attributes: {
               code: '706300',
               analytical_section: '9A54C'
             }
           }
         },
         headers: upload_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the events were correctly created
    db_events = Event.where(title: name)
    assert_equal 10, db_events.count
    assert(db_events.all? { |event| !event.event_image.attachment.nil? })
    assert(db_events.all? { |event| !event.description.empty? })
    assert(db_events.all? { |event| event.availability.start_at.to_date >= 1.week.from_now.to_date })
    assert(db_events.all? { |event| event.availability.start_at.to_date <= 10.weeks.from_now.end_of_day.to_date })
    assert(db_events.all? { |event| event.availability.end_at.to_date >= 1.week.from_now.to_date })
    assert(db_events.all? { |event| event.availability.end_at.to_date <= 10.weeks.from_now.end_of_day.to_date })
    assert(db_events.all?(&:all_day?))
    assert(db_events.all? { |event| event.amount == 2000 })
    assert(db_events.all? { |event| event.event_theme_ids == [1] })
    assert(db_events.all? { |event| event.category_id == 2 })
    assert(db_events.all? { |event| event.age_range_id == 1 })
    assert(db_events.all? { |event| event.event_files.count == 2 })
    assert(db_events.all? { |event| !event.event_files[0].attachment.nil? })
    assert(db_events.all? { |event| !event.event_files[1].attachment.nil? })
    assert(db_events.all? { |event| event.event_price_categories[0].price_category_id == 1 })
    assert(db_events.all? { |event| event.event_price_categories[0].amount == 1000 })
    assert(db_events.all? { |event| event.event_price_categories[1].price_category_id == 2 })
    assert(db_events.all? { |event| event.event_price_categories[1].amount == 1500 })
    assert(db_events.all? { |event| event.advanced_accounting.code == '706300' })
    assert(db_events.all? { |event| event.advanced_accounting.analytical_section == '9A54C' })
  end

  test 'create a simple recurrent event' do
    name = 'Fablab party'
    post '/api/events',
         params: {
           event: {
             title: name,
             event_image_attributes: {
               attachment: fixture_file_upload('event/Party.jpg')
             },
             description: 'Come party tonight at the fablab...',
             start_date: 2.weeks.from_now,
             end_date: 2.weeks.from_now,
             all_day: false,
             start_time: '18:00',
             end_time: '23:29',
             amount: 20,
             category_id: 2,
             recurrence: 'month',
             recurrence_end_at: 2.weeks.from_now + 3.months
           }
         },
         headers: upload_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the events were correctly created
    db_events = Event.where(title: name)
    assert_equal 4, db_events.count
    assert(db_events.all? { |event| !event.event_image.attachment.nil? })
    assert(db_events.all? { |event| !event.description.empty? })
    assert(db_events.all? { |event| event.availability.start_at.to_date >= 2.weeks.from_now.to_date })
    assert(db_events.all? { |event| event.availability.start_at.to_date <= 2.weeks.from_now.end_of_day.to_date + 3.months })
    assert(db_events.all? { |event| event.availability.end_at.to_date >= 2.weeks.from_now.to_date })
    assert(db_events.all? { |event| event.availability.end_at.to_date <= 2.weeks.from_now.end_of_day.to_date + 3.months })
    assert(db_events.none?(&:all_day?))
    assert(db_events.all? { |event| event.amount == 2000 })
    assert(db_events.all? { |event| event.event_theme_ids.empty? })
    assert(db_events.all? { |event| event.category_id == 2 })
    assert(db_events.all? { |event| event.age_range_id.nil? })
    assert(db_events.all? { |event| event.event_files.count.zero? })
    assert(db_events.all? { |event| event.event_price_categories.count.zero? })
  end
end
