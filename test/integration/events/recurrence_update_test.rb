# frozen_string_literal: true

require 'test_helper'

module Events; end

class Events::RecurrenceUpdateTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'update a recurrent event' do
    # first create a recurrent event
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

    # Update all the events
    event = db_events.first
    new_title = 'Skateboard party'
    new_descr = 'Come make a skateboard tonight at the Fablab'
    new_image = 'event/Skateboard.jpg'
    new_file = 'document.pdf'
    put "/api/events/#{event&.id}", params: {
      event: {
        title: new_title,
        event_image_attributes: {
          attachment: fixture_file_upload(new_image)
        },
        event_files_attributes: {
          '0' => { attachment: fixture_file_upload(new_file) }
        },
        description: new_descr,
        category_id: 1,
        event_theme_ids: [1],
        age_range_id: 1,
        start_date: event&.availability&.start_at,
        end_date: event&.availability&.end_at,
        all_day: false,
        start_time: '18:00',
        end_time: '23:29',
        amount: 20
      },
      edit_mode: 'all'
    }, headers: upload_headers

    # Check response format & status
    assert_response :success, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the events were correctly updated
    res = json_response(response.body)
    assert_equal 'update', res[:action]
    assert_equal 4, res[:total]
    assert_equal 4, res[:updated]
    res[:details][:events].each do |res_event|
      assert res_event[:status]
      db_event = Event.find(res_event[:event][:id])
      assert_equal new_title, db_event.title
      assert_equal new_descr, db_event.description
      assert_equal 1, db_event.category_id
      assert_includes db_event.event_theme_ids, 1
      assert_equal 1, db_event.age_range_id
      assert FileUtils.compare_file(
        File.join(ActionDispatch::IntegrationTest.fixture_path, "files/#{new_image}"),
        db_event.event_image.attachment.file.path
      )
      assert FileUtils.compare_file(
        File.join(ActionDispatch::IntegrationTest.fixture_path, "files/#{new_file}"),
        db_event.event_files[0].attachment.file.path
      )
    end

    # Update again but only the next events
    event = Event.includes(:availability).where(title: new_title).order('availabilities.start_at').limit(2)[1]
    put "/api/events/#{event&.id}", params: {
      event: {
        title: event.title,
        description: event.description,
        event_image_attributes: {
          id: event.event_image.id
        },
        category_id: 2,
        event_theme_ids: [1],
        age_range_id: 1,
        start_date: event.availability.start_at,
        end_date: event.availability.end_at,
        all_day: false,
        start_time: '18:00',
        end_time: '23:29',
        amount: 20
      },
      edit_mode: 'next'
    }.to_json, headers: default_headers

    # Check response format & status
    assert_response :success, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the events were correctly updated
    res = json_response(response.body)
    assert_equal 'update', res[:action]
    assert_equal 3, res[:total]
    assert_equal 3, res[:updated]
    res[:details][:events].each do |res_event|
      assert res_event[:status]
      db_event = Event.find(res_event[:event][:id])
      assert_equal 2, db_event.category_id
      assert FileUtils.compare_file(
        File.join(ActionDispatch::IntegrationTest.fixture_path, "files/#{new_image}"),
        db_event.event_image.attachment.file.path
      )
    end
  end
end
