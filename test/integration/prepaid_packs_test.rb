# frozen_string_literal: true

require 'test_helper'

class PrepaidPacksTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'create a prepaid pack' do
    post '/api/prepaid_packs',
         params: {
           pack: {
             priceable_id: 1,
             priceable_type: 'Machine',
             group_id: 1,
             amount: 10,
             minutes: 120,
             validity_count: 1,
             validity_interval: 'month'
           }
         }.to_json,
         headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the correct prepaid pack was created
    res = json_response(response.body)
    pack = PrepaidPack.where(id: res[:id]).first
    assert_not_nil pack, 'prepaid pack was not created in database'

    assert_equal 1, res[:priceable_id]
    assert_equal 'Machine', res[:priceable_type]
    assert_equal 1, res[:group_id]
    assert_equal 10, res[:amount]
    assert_equal 120, res[:minutes]
    assert_equal 1, res[:validity_count]
    assert_equal 'month', res[:validity_interval]
  end

  test 'update a prepaid pack' do
    patch '/api/prepaid_packs/1',
          params: {
            pack: {
              amount: 20
            }
          }.to_json,
          headers: default_headers

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the prepaid pack was updated
    res = json_response(response.body)
    assert_equal 1, res[:id]
    assert_equal 20, res[:amount]
  end

  test 'list all prepaid packs' do
    get '/api/prepaid_packs'

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the list items are ok
    pack = json_response(response.body)
    assert_equal PrepaidPack.count, pack.count
  end

  test 'delete prepaid pack' do
    pack = PrepaidPack.create!(priceable_type: 'Machine', priceable_id: 2, group_id: 2, amount: 100, minutes: 240)
    delete "/api/prepaid_packs/#{pack.id}"
    assert_response :success
    assert_empty response.body
    assert_raise ActiveRecord::RecordNotFound do
      pack.reload
    end
  end

  test 'cannot delete an used prepaid pack' do
    delete '/api/prepaid_packs/1'
    assert_response :forbidden
    assert_not_nil PrepaidPack.find(1)
  end
end
