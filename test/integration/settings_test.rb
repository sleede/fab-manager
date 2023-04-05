# frozen_string_literal: true

require 'test_helper'

class SettingsTest < ActionDispatch::IntegrationTest
  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'update setting value' do
    put '/api/settings/fablab_name',
        params: {
          setting: {
            value: 'Test Fablab'
          }
        }
    assert_equal 200, response.status
    assert_match Mime[:json].to_s, response.content_type
    resp = json_response(response.body)
    assert_equal 'fablab_name', resp[:setting][:name]
    assert_equal 'Test Fablab', resp[:setting][:value]

    # Check record
    setting = Setting.find_by(name: resp[:setting][:name])
    assert_not_nil setting, 'setting was not found in database'
    assert_equal 2, setting.history_values.count, 'all historical values were not found'
    assert_includes setting.history_values.map(&:value), 'Fab Lab de La Casemate', 'previous parameter was not saved'
    assert_includes setting.history_values.map(&:value), 'Test Fablab', 'current parameter was not saved'
  end

  test 'bulk update some settings' do
    patch '/api/settings/bulk_update',
          params: {
            settings: [
              { name: 'fablab_name', value: 'Test Fablab' },
              { name: 'name_genre', value: 'male' },
              { name: 'main_color', value: '#ea519a' }
            ]
          }
    assert_equal 200, response.status
    assert_match Mime[:json].to_s, response.content_type
    resp = json_response(response.body)
    assert(resp[:settings].any? { |s| s[:name] == 'fablab_name' && s[:value] == 'Test Fablab' })
    assert(resp[:settings].any? { |s| s[:name] == 'name_genre' && s[:value] == 'male' })
    assert(resp[:settings].any? { |s| s[:name] == 'main_color' && s[:value] == '#ea519a' })
  end

  test 'transactional bulk update fails' do
    old_css = Setting.get('home_css')
    old_color = Setting.get('main_color')

    patch '/api/settings/bulk_update?transactional=true',
          params: {
            settings: [
              { name: 'home_css', value: 'INVALID CSS{{!!' },
              { name: 'main_color', value: '#ea519a' }
            ]
          }
    assert_equal 200, response.status
    assert_match Mime[:json].to_s, response.content_type
    resp = json_response(response.body)
    assert_not_nil resp[:settings].first[:error]
    assert_match(/Error: Invalid CSS after/, resp[:settings].first[:error].first)

    # Check values havn't changed
    assert_equal old_css, Setting.get('home_css')
    assert_equal old_color, Setting.get('main_color')
  end

  test 'update setting with wrong name' do
    put '/api/settings/does_not_exists',
        params: {
          setting: {
            value: 'ERROR EXPECTED'
          }
        }
    assert_equal 422, response.status
    assert_match(/Name is not included in the list/, response.body)
  end

  test 'show setting' do
    get '/api/settings/fablab_name'

    assert_equal 200, response.status
    assert_match Mime[:json].to_s, response.content_type
    resp = json_response(response.body)
    assert_equal 'fablab_name', resp[:setting][:name], 'wrong parameter name'
    assert_equal 'Fab Lab de La Casemate', resp[:setting][:value], 'wrong parameter value'
  end
end
