# frozen_string_literal: true

require 'test_helper'

module Credits; end

class Credits::UserInfoTest < ActionDispatch::IntegrationTest
  def setup
    @user_without_subscription = User.find_by(username: 'lseguin')
    @user_with_subscription = User.find_by(username: 'kdumas')
  end

  test 'user fetch her credits info' do
    login_as(@user_with_subscription, scope: :user)
    get "/api/credits/user/#{@user_with_subscription.id}/Machine"

    # Check response format & status
    assert_equal 200, response.status
    assert_match Mime[:json].to_s, response.content_type

    # Check the correct credits was returned
    credits = json_response(response.body)
    assert_equal @user_with_subscription.subscribed_plan.credits.where(creditable_type: 'Machine').count,
                 credits.length,
                 'not all credits were returned'
  end

  test 'user without credits fetch his credits info' do
    login_as(@user_without_subscription, scope: :user)
    get "/api/credits/user/#{@user_without_subscription.id}/Machine"

    # Check response format & status
    assert_equal 200, response.status
    assert_match Mime[:json].to_s, response.content_type

    # Check the correct credits was returned
    credits = json_response(response.body)
    assert_equal 0, credits.length, 'unexpected credits returned'
  end

  test 'user tries to fetch credits info from another user' do
    login_as(@user_without_subscription, scope: :user)
    get "/api/credits/user/#{@user_with_subscription.id}/Machine"

    assert_equal 403, response.status
  end
end
