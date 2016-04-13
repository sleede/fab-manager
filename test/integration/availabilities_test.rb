class AvailabilitiesTest < ActionDispatch::IntegrationTest
  setup do
    admin = User.with_role(:admin).first
    login_as(admin, scope: :user)
  end

  test 'return availability by id' do
    a = Availability.take

    get "/api/availabilities/#{a.id}"

    # Check response format & status
    assert_equal 200, response.status
    assert_equal Mime::JSON, response.content_type

    # Check the correct availability was returned
    availability = json_response(response.body)
    assert_equal a.id, availability[:id], 'availability id does not match'
  end

  test 'get machine availabilities' do
    m = Machine.find_by_slug('decoupeuse-vinyle')

    get "/api/availabilities/machines/#{m.id}"
  end
end
