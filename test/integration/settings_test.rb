class SettingsTest < ActionDispatch::IntegrationTest

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'update setting value' do
    put '/api/settings/fablab_name',
        setting: {
          value: 'Test Fablab'
        }
    assert_equal 200, response.status
    assert_equal Mime::JSON, response.content_type
    resp = json_response(response.body)
    assert_equal 'fablab_name', resp[:setting][:name]
    assert_equal 'Test Fablab', resp[:setting][:value]

    # Check record
    setting = Setting.find_by_name(resp[:setting][:name])
    assert_not_nil setting, 'setting was not found in database'
    assert_equal 2, setting.history_values.count, 'all historical values were not found'
    assert_includes setting.history_values.map(&:value), 'Fab Lab de La Casemate', 'previous parameter was not saved'
    assert_includes setting.history_values.map(&:value), 'Test Fablab', 'current parameter was not saved'
  end


  test 'update setting with wrong name' do
    put '/api/settings/does_not_exists',
        setting: {
          value: 'ERROR EXPECTED'
        }
    assert_equal 422, response.status
    assert_match /Name is not included in the list/, response.body
  end

  test 'show setting' do
    get '/api/settings/fablab_name'

    assert_equal 200, response.status
    assert_equal Mime::JSON, response.content_type
    resp = json_response(response.body)
    assert_equal 'fablab_name', resp[:setting][:name], 'wrong parameter name'
    assert_equal 'Fab Lab de La Casemate', resp[:setting][:value], 'wrong parameter value'
  end

end
