class AvailabilitiesTest < ActionDispatch::IntegrationTest
  setup do
    admin = User.with_role(:admin).first
    login_as(admin, scope: :user)
  end

  test "return availability by id" do
    a = Availability.take

    get "/api/availabilities/#{a.id}"
    assert_equal 200, response.status
  end
end
