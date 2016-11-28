class AdminsTest < ActionDispatch::IntegrationTest

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

  test 'create an admin' do

    post '/api/admins',
         {
             admin: {
                 username: 'glepower',
                 email: 'gerard.lepower@admins.net',
                 profile_attributes: {
                     first_name: 'Gérard',
                     last_name: 'Lepower',
                     gender: true,
                     birthday: '1999-09-19',
                     phone: '0547124852',
                     address_attributes: {
                         address: '6 Avenue Henri de Bournazel, 19000 Tulle'
                     }
                 }
             }
         }.to_json,
         default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_equal Mime::JSON, response.content_type

    # Check the correct admin was created
    admin = json_response(response.body)
    user = User.where(id: admin[:admin][:id]).first
    assert_not_nil user, 'admin was not created in database'

    # Check he's got the admin role
    assert user.has_role?(:admin), 'admin does not have the admin role'
  end
end