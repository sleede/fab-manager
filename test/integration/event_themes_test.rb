# frozen_string_literal: true

require 'test_helper'

class EventThemesTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'create an event theme' do
    post '/api/event_themes',
         params: {
           name: 'Cuisine'
         }.to_json,
         headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the correct event theme was created
    res = json_response(response.body)
    theme = EventTheme.where(id: res[:id]).first
    assert_not_nil theme, 'event theme was not created in database'

    assert_equal 'Cuisine', res[:name]
  end

  test 'update an event theme' do
    patch '/api/event_themes/1',
          params: {
            name: 'DIY'
          }.to_json,
          headers: default_headers

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the event theme was updated
    res = json_response(response.body)
    assert_equal 1, res[:id]
    assert_equal 'DIY', res[:name]
  end

  test 'list all event themes' do
    get '/api/event_themes'

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the list items are ok
    themes = json_response(response.body)
    assert_equal EventTheme.count, themes.count
  end

  test 'delete an event theme' do
    theme = EventTheme.create!(name: 'delete me')
    delete "/api/event_themes/#{theme.id}"
    assert_response :success
    assert_empty response.body
    assert_raise ActiveRecord::RecordNotFound do
      theme.reload
    end
  end
end
