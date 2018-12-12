class MemebersTest < ActionDispatch::IntegrationTest

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'admin creates member' do

    group_id = Group.first.id
    email = 'robert.dubois@gmail.com'

    VCR.use_cassette('members_admin_create_success') do
      post members_path, { user: {
        username: 'bob',
        email: email,
        group_id: group_id,
        profile_attributes: {
          gender: true,
          last_name: 'Dubois',
          first_name: 'Robert',
          birthday: '2018-02-08',
          phone: '0485232145'
        }
      } }.to_json, default_headers
    end

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_equal Mime::JSON, response.content_type

    # Check the user was subscribed
    user = json_response(response.body)
    assert_equal email, user[:email], "user's mail does not match"

  end
end
