class SubscriptionsTest < ActionDispatch::IntegrationTest


  setup do
    @user = User.find_by_username('jdupont')
    login_as(@user, scope: :user)
  end

  test "user take a subscription" do
    plan = Plan.where(group_id: @user.group.id, type: 'Plan').first

    post '/api/subscriptions',
         {
           subscription: {
             plan_id: plan.id,
             user_id: @user.id,
             card_token: stripe_card_token
           }
         }.to_json,
         {
           'Accept' => Mime::JSON,
           'Content-Type' => Mime::JSON.to_s
         }

    assert_equal 201, response.status, response.body
    assert_equal Mime::JSON, response.content_type

    subscription = json_response(response.body)
    assert_equal plan.id, subscription[:plan_id]

  end

end