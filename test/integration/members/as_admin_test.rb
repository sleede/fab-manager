# frozen_string_literal: true

require 'test_helper'

class MembersTest < ActionDispatch::IntegrationTest
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
      post members_path, params: { user: {
        username: 'bob',
        email: email,
        group_id: group_id,
        profile_attributes: {
          last_name: 'Dubois',
          first_name: 'Robert',
          phone: '0485232145'
        },
        invoicing_profile_attributes: {
          organization: false,
          address_attributes: {
            address: '21 grand rue, 73110 Bourget-en-Huile'
          }
        },
        statistic_profile_attributes: {
          gender: true,
          birthday: '2018-02-08'
        }
      } }.to_json, headers: default_headers
    end

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check that the user's match
    user = json_response(response.body)
    assert_equal email, user[:email], "user's mail does not match"
    assert_equal group_id, user[:group_id], "user's group does not match"
  end

  test 'admin fails to update member group' do
    user = User.friendly.find('kdumas')

    # we cannot update an kevin's group because he's got a running subscription
    put "/api/members/#{user.id}", params: { user: {
      group_id: 1
    } }.to_json, headers: default_headers

    # Check response format & status
    assert_equal 422, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check error message
    res = json_response(response.body)
    assert_equal I18n.t('members.unable_to_change_the_group_while_a_subscription_is_running'), res[:group_id][0], 'invalid error message'
  end

  test 'admin successfully updates a member' do
    user = User.friendly.find('vlonchamp')
    user_hash = { user: JSON.parse(user.to_json) }
    instagram = 'https://www.instagram.com/vanessa/'

    put "/api/members/#{user.id}", params: user_hash.deep_merge(
      user: {
        'group_id' => 1,
        'profile_attributes' => {
          'instagram' => instagram
        }
      }
    ).to_json, headers: default_headers

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check update result
    res = json_response(response.body)
    assert_equal 1, res[:group_id], "user's group does not match"
    assert_equal instagram, res[:profile_attributes][:instagram], "user's social network not updated"
  end

  test 'admin search for autocompletion of a member s name' do
    get '/api/members/search/kevin?subscription=true'

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check search result
    res = json_response(response.body)
    assert_equal 1, res.length

    assert_match(/Kevin/, res[0][:name])
  end

  test 'admin changes the group of a member' do
    user = User.find(2)
    patch "/api/members/#{user.id}/",
          params: {
            user: {
              id: user.id,
              group_id: 2
            }
          }

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check search result
    res = json_response(response.body)
    assert_equal 2, res[:group_id]
  end
end
