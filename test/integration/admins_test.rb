# frozen_string_literal: true

require 'test_helper'

class AdminsTest < ActionDispatch::IntegrationTest
  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'create an admin' do
    post '/api/admins',
         params: {
           admin: {
             username: 'glepower',
             email: 'gerard.lepower@admins.net',
             profile_attributes: {
               first_name: 'Gérard',
               last_name: 'Lepower',
               phone: '0547124852'
             },
             invoicing_profile_attributes: {
               address_attributes: {
                 address: '6 Avenue Henri de Bournazel, 19000 Tulle'
               }
             },
             statistic_profile_attributes: {
               gender: true,
               birthday: '1999-09-19'
             }
           }
         }.to_json,
         headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the correct admin was created
    admin = json_response(response.body)
    user = User.where(id: admin[:admin][:id]).first
    assert_not_nil user, 'admin was not created in database'

    # Check he's got the admin role
    assert user.has_role?(:admin), 'admin does not have the admin role'
  end

  test 'list all admins' do
    get '/api/admins'

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the list items are ok
    admins = json_response(response.body)
    assert_equal 1, admins.count, 'not all admins retrieved'
    assert_equal @admin.id, admins[:admins][0][:id], 'admin id matches'
    assert_equal @admin.profile.user_avatar.id,
                 admins[:admins][0][:profile_attributes][:user_avatar][:id],
                 'admin avatar does not match'
  end

  test 'admin cannot delete himself' do
    delete "/api/admins/#{@admin.id}"

    assert_response :unauthorized
  end
end
