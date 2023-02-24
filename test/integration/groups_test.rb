# frozen_string_literal: true

require 'test_helper'

class GroupsTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'create a group' do
    post '/api/groups',
         params: {
           name: 'Strange people',
           disabled: true
         }.to_json,
         headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the correct group was created
    res = json_response(response.body)
    group = Group.where(id: res[:id]).first
    assert_not_nil group, 'group was not created in database'

    assert_equal 'Strange people', res[:name]
    assert_equal true, res[:disabled]
  end

  test 'update a group' do
    patch '/api/groups/1',
          params: {
            name: 'Normal people'
          }.to_json,
          headers: default_headers

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the group was updated
    res = json_response(response.body)
    assert_equal 1, res[:id]
    assert_equal 'Normal people', res[:name]
  end

  test 'list all groups' do
    get '/api/groups'

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the list items are ok
    groups = json_response(response.body)
    assert_equal Group.count, groups.count
  end

  test 'delete a group' do
    group = Group.create!(name: 'delete me')
    delete "/api/groups/#{group.id}"
    assert_response :success
    assert_empty response.body
    assert_raise ActiveRecord::RecordNotFound do
      group.reload
    end
  end

  test 'unable to delete a used group' do
    delete '/api/groups/1'
    assert_response :forbidden
    assert_not_nil Group.find(1)
  end
end
