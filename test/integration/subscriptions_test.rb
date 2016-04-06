class SubscriptionsTest < ActionDispatch::IntegrationTest


  setup do
    @user = User.find_by_username('jdupond')
    login_as(@user, scope: :user)
  end

  test "user take a subscription" do
    plan = Plan.where(group_id: @user.group.id, type: 'Plan').first

    VCR.use_cassette("subscriptions_user_create_success") do
      post '/api/subscriptions',
           {
             subscription: {
               plan_id: plan.id,
               user_id: @user.id,
               card_token: stripe_card_token
             }
           }.to_json, default_headers
  end

    assert_equal 201, response.status, response.body
    assert_equal Mime::JSON, response.content_type

    subscription = json_response(response.body)
    assert_equal plan.id, subscription[:plan_id]

  end

end