# frozen_string_literal: true

require 'test_helper'

module OpenApi; end

class OpenApi::UsersTest < ActionDispatch::IntegrationTest
  def setup
    @token = OpenAPI::Client.find_by(name: 'minitest').token
  end

  test 'list all users' do
    get '/open_api/v1/users', headers: open_api_headers(@token)
    assert_response :success
    assert_match Mime[:json].to_s, response.content_type

    users = json_response(response.body)
    assert_equal User.count, users[:users].length
    assert_not_nil(users[:users].detect { |u| u[:external_id] == 'J5821-4' })
    assert(users[:users].all? { |u| %w[man woman].include?(u[:gender]) })
    assert(users[:users].all? { |u| u[:organization] != User.find(u[:id]).invoicing_profile.organization.nil? })
    assert(users[:users].all? { |u| u[:invoicing_profile_id].present? })
    assert(users[:users].all? { |u| u[:full_name].present? })
    assert(users[:users].all? { |u| u[:first_name].present? })
    assert(users[:users].all? { |u| u[:last_name].present? })
    assert(users[:users].any? { |u| u[:address].present? })
    assert(users[:users].all? { |u| u[:group][:id] == User.find(u[:id]).group_id })
    assert(users[:users].all? { |u| u[:group][:name].present? })
    assert(users[:users].all? { |u| u[:group][:slug].present? })
  end

  test 'list all users with pagination' do
    get '/open_api/v1/users?page=1&per_page=5', headers: open_api_headers(@token)
    assert_response :success
    assert_match Mime[:json].to_s, response.content_type

    users = json_response(response.body)
    assert_equal 5, users[:users].length
  end

  test 'list all users filtering by IDs' do
    get '/open_api/v1/users?user_id=[3,4,5]', headers: open_api_headers(@token)
    assert_response :success
    assert_match Mime[:json].to_s, response.content_type

    users = json_response(response.body)
    assert users[:users].count.positive?
    assert(users[:users].all? { |user| [3, 4, 5].include?(user[:id]) })
  end

  test 'list all users filtering by IDs other syntax' do
    get '/open_api/v1/users?user_id[]=3&user_id[]=4&user_id[]=5', headers: open_api_headers(@token)
    assert_response :success
    assert_match Mime[:json].to_s, response.content_type

    users = json_response(response.body)
    assert users[:users].count.positive?
    assert(users[:users].all? { |user| [3, 4, 5].include?(user[:id]) })
  end

  test 'list a user filtering by ID' do
    get '/open_api/v1/users?user_id=2', headers: open_api_headers(@token)
    assert_response :success
    assert_match Mime[:json].to_s, response.content_type

    users = json_response(response.body)
    assert_equal 1, users[:users].count
    assert_equal 2, users[:users].first[:id]
  end

  test 'list all users filtering by email' do
    get '/open_api/v1/users?email=jean.dupond@gmail.com', headers: open_api_headers(@token)
    assert_response :success
    assert_match Mime[:json].to_s, response.content_type

    users = json_response(response.body)
    assert_equal 1, users[:users].count
    assert_equal 'jean.dupond@gmail.com', users[:users].first[:email]
  end

  test 'list all users created after date' do
    get '/open_api/v1/users?created_after=2018-01-01T00:00:00+01:00', headers: open_api_headers(@token)
    assert_response :success
    assert_match Mime[:json].to_s, response.content_type

    users = json_response(response.body)
    assert users[:users].count.positive?
    assert(users[:users].all? { |u| Time.zone.parse(u[:created_at]) >= Time.zone.parse('2018-01-01T00:00:00+01:00') })
  end
end
