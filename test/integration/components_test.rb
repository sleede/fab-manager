# frozen_string_literal: true

require 'test_helper'

class ComponentsTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'create a component' do
    post '/api/components',
         params: {
           name: 'Wood'
         }.to_json,
         headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the correct component was created
    res = json_response(response.body)
    comp = Component.where(id: res[:id]).first
    assert_not_nil comp, 'component was not created in database'

    assert_equal 'Wood', res[:name]
  end

  test 'update a component' do
    patch '/api/components/1',
          params: {
            name: 'Silicon'
          }.to_json,
          headers: default_headers

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the component was updated
    res = json_response(response.body)
    assert_equal 1, res[:id]
    assert_equal 'Silicon', res[:name]
  end

  test 'list all components' do
    get '/api/components'

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the list items are ok
    comps = json_response(response.body)
    assert_equal Component.count, comps.count
  end

  test 'delete a component' do
    comp = Component.create!(name: 'delete me')
    delete "/api/components/#{comp.id}"
    assert_response :success
    assert_empty response.body
    assert_raise ActiveRecord::RecordNotFound do
      comp.reload
    end
  end
end
