class AvailabilitiesTest < ActionDispatch::IntegrationTest
  setup do
    @profile = Profile.create!(gender: true, birthday: 20.years.ago, first_name: "Admin", last_name: "Sleede", phone: "06542868451")
    @admin = User.create!(cgu: true, username: 'blabla', email: 'abc@sleede.com', password: 'kikoulol', password_confirmation: 'kikoulol', profile: @profile)
    @admin.add_role(:admin)
    login_as(@admin, scope: :user)
  end

  test "return availability by id" do
    a = Availability.create!(start_at: Time.now, end_at: 2.hours.from_now, available_type: 'trainings')


    get "/api/availabilities/#{a.id}"
    assert_equal 200, response.status
  end
end
