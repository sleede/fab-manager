# frozen_string_literal: true

require 'test_helper'

class CouponsTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    @member = User.find_by(username: 'jdupond')
    @coupon = Coupon.first
  end

  test 'unauthenticated visitor cannot access coupons index or show' do
    get '/api/coupons', headers: default_headers
    assert_response :unauthorized

    get "/api/coupons/#{@coupon.id}", headers: default_headers
    assert_response :unauthorized
  end

  test 'regular member receives 403 forbidden on index and show' do
    login_as(@member, scope: :user)

    get '/api/coupons', headers: default_headers
    assert_response :forbidden

    get "/api/coupons/#{@coupon.id}", headers: default_headers
    assert_response :forbidden
  end

  test 'admin can list coupons with all five valid filters' do
    login_as(@admin, scope: :user)

    # 1. Default (no filter)
    get '/api/coupons', headers: default_headers
    assert_response :success
    data = json_response(response.body)
    refute_empty data
    assert data.first.key?(:total)
    assert_equal Coupon.count, data.first[:total]

    # 2. filter=all
    get '/api/coupons?filter=all', headers: default_headers
    assert_response :success
    data_all = json_response(response.body)
    assert_equal Coupon.count, data_all.first[:total]

    # 3. filter=active
    get '/api/coupons?filter=active', headers: default_headers
    assert_response :success
    data_active = json_response(response.body)
    active_count = Coupon.active.count(:all)
    expected_active = active_count.is_a?(Hash) ? active_count.size : active_count
    assert_equal expected_active, data_active.first[:total] if data_active.any?

    # 4. filter=disabled
    get '/api/coupons?filter=disabled', headers: default_headers
    assert_response :success
    data_disabled = json_response(response.body)
    assert_equal Coupon.disabled.count, data_disabled.first[:total] if data_disabled.any?

    # 5. filter=expired
    get '/api/coupons?filter=expired', headers: default_headers
    assert_response :success
    data_expired = json_response(response.body)
    assert_equal Coupon.expired.count, data_expired.first[:total] if data_expired.any?

    # 6. filter=sold_out
    get '/api/coupons?filter=sold_out', headers: default_headers
    assert_response :success
    data_sold_out = json_response(response.body)
    sold_count = Coupon.sold_out.count(:all)
    expected_sold = sold_count.is_a?(Hash) ? sold_count.size : sold_count
    assert_equal expected_sold, data_sold_out.first[:total] if data_sold_out.any?
  end

  test 'admin can view coupon show' do
    login_as(@admin, scope: :user)

    get "/api/coupons/#{@coupon.id}", headers: default_headers
    assert_response :success
    data = json_response(response.body)
    assert_equal @coupon.code, data[:code]
  end

  test 'rejects arbitrary class methods and unknown filters with 400 bad request without side effects' do
    login_as(@admin, scope: :user)

    initial_coupons_count = Coupon.count
    assert initial_coupons_count.positive?, 'Expected coupons to exist initially'

    # FM-03: Attempt destructive class method invocation
    get '/api/coupons?filter=delete_all', headers: default_headers
    assert_response :bad_request
    assert_equal initial_coupons_count, Coupon.count, 'Coupons should not be deleted'

    get '/api/coupons?filter=destroy_all', headers: default_headers
    assert_response :bad_request
    assert_equal initial_coupons_count, Coupon.count

    # Unknown filter name
    get '/api/coupons?filter=unknown_filter', headers: default_headers
    assert_response :bad_request

    # Non-string filter parameter
    get '/api/coupons?filter[]=', headers: default_headers
    assert_response :bad_request

    get '/api/coupons?filter[name]=all', headers: default_headers
    assert_response :bad_request
  end
end
