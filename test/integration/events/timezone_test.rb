# frozen_string_literal: true

require 'test_helper'

module Events; end

class Events::TimezoneTest < ActionDispatch::IntegrationTest
  setup do
    admin = User.with_role(:admin).first
    login_as(admin, scope: :user)
  end

  test 'create an event from a negative timezone' do
    # Create a new event
    post '/api/events',
         params: {
           event: {
             title: 'Street child skateboard',
             description: '<p>Build your own skateboard for children to ride in the street</p>',
             category_id: 2,
             start_date: '2023-06-14T20:00:00.000-04:00',
             end_date: '2023-06-14T20:00:00.000-04:00',
             start_time: '09:48',
             end_time: '11:48',
             recurrence: 'none',
             recurrence_end_at: '',
             nb_total_places: 'NaN',
             amount: '35',
             advanced_accounting_attributes: {
               code: '',
               analytical_section: ''
             },
             event_image_attributes: {
               attachment: fixture_file_upload('event/Skateboard.jpg')
             }
           }
         }.to_json,
         headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the event was created correctly
    event = json_response(response.body)
    e = Event.find_by(id: event[:id])
    assert_not_nil e, 'Event was not created in database'

    assert_equal '2023-06-15', e.availability.start_at.to_date.iso8601
    assert_equal '2023-06-15', e.availability.end_at.to_date.iso8601
    assert_equal '09:48', e.availability.start_at.strftime('%R')
    assert_equal '11:48', e.availability.end_at.strftime('%R')
  end
end
