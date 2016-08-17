class SettingsTest < ActionDispatch::IntegrationTest

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  test 'update setting value' do
    put '/api/settings/fablab_name',
      {
        setting: {
          value: 'Test Fablab'
        }
      }
    assert_equal 200, response.status
    assert_equal Mime::JSON, response.content_type
    resp = json_response(response.body)
    assert_equal 'fablab_name', resp[:setting][:name]
    assert_equal 'Test Fablab', resp[:setting][:value]
  end


  test 'update setting with wrong name' do
    put '/api/settings/does_not_exists',
        {
            setting: {
                value: 'ERROR EXPECTED'
            }
        }
    assert_equal 422, response.status
    assert_match /Name is not included in the list/, response.body
  end

end
