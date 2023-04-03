# frozen_string_literal: true

require 'test_helper'

class ListTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'all members' do
    post '/api/members/list', params: { query: {
      search: '',
      order_by: 'id',
      page: 1,
      size: 20
    } }.to_json, headers: default_headers

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check that we have all users
    users = json_response(response.body)
    assert_equal User.members.count, users.size, 'some users are missing'

    # Check that users are ordered by id
    first_user = User.members.order(:id).limit(1).first
    last_user = User.members.order(id: :desc).limit(1).first
    assert_equal first_user.id, users.first[:id]
    assert_equal last_user.id, users.last[:id]
  end
end
