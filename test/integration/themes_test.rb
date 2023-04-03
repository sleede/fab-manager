# frozen_string_literal: true

require 'test_helper'

class ThemesTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'create a theme' do
    post '/api/themes',
         params: {
           name: 'Cuisine'
         }.to_json,
         headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the correct tag was created
    res = json_response(response.body)
    theme = Theme.where(id: res[:id]).first
    assert_not_nil theme, 'theme was not created in database'

    assert_equal 'Cuisine', res[:name]
  end

  test 'update a theme' do
    patch '/api/themes/1',
          params: {
            name: 'Objets de la maison'
          }.to_json,
          headers: default_headers

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the tag was updated
    res = json_response(response.body)
    assert_equal 1, res[:id]
    assert_equal 'Objets de la maison', res[:name]
  end

  test 'list all themes' do
    get '/api/themes'

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the list items are ok
    themes = json_response(response.body)
    assert_equal Theme.count, themes.count
  end

  test 'delete a theme' do
    theme = Theme.create!(name: 'delete me')
    delete "/api/themes/#{theme.id}"
    assert_response :success
    assert_empty response.body
    assert_raise ActiveRecord::RecordNotFound do
      theme.reload
    end
  end
end
