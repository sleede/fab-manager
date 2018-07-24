class Subscriptions::RenewAsUserTest < ActionDispatch::IntegrationTest


  setup do
    @user = User.find_by(username: 'lseguin')
    login_as(@user, scope: :user)
  end

  test 'user successfully renew a subscription after it has ended' do
    plan = Plan.find_by(group_id: @user.group.id, type: 'Plan', base_name: 'Mensuel')

    VCR.use_cassette("subscriptions_user_renew_success", :erb => true) do
      post '/api/subscriptions',
           {
             subscription: {
               plan_id: plan.id,
               user_id: @user.id,
               card_token: stripe_card_token
             }
           }.to_json, default_headers
    end

    # Check response format & status
    assert_equal 201, response.status, "API does not return the expected status."+response.body
    assert_equal Mime::JSON, response.content_type

    # Check the correct plan was subscribed
    subscription = json_response(response.body)
    assert_equal plan.id, subscription[:plan_id], 'subscribed plan does not match'

    # Check that the user has the correct subscription
    assert_not_nil @user.subscription, "user's subscription was not found"
    assert (@user.subscription.expired_at > DateTime.now), "user's subscription expiration was not updated ... VCR cassettes may be outdated, please check the gitlab wiki"
    assert_in_delta 5, (DateTime.now.to_i - @user.subscription.updated_at.to_i), 10, "user's subscription was not updated recently"

    # Check that the credits were reset correctly
    assert_empty @user.users_credits, 'credits were not reset'

    # Check notifications were sent for every admins
    notifications = Notification.where(notification_type_id: NotificationType.find_by_name('notify_admin_subscribed_plan'), attached_object_type: 'Subscription', attached_object_id: subscription[:id])
    assert_not_empty notifications, 'no notifications were created'
    notified_users_ids = notifications.map {|n| n.receiver_id }
    User.admins.each do |adm|
      assert_includes notified_users_ids, adm.id, "Admin #{adm.id} was not notified"
    end

    # Check generated invoice
    invoice = Invoice.find_by(invoiced_type: 'Subscription', invoiced_id: subscription[:id])
    assert_invoice_pdf invoice
    assert_equal plan.amount, invoice.total, 'Invoice total price does not match the bought subscription'
  end



  test 'user fails to renew a subscription' do
    plan = Plan.find_by(group_id: @user.group.id, type: 'Plan', base_name: 'Mensuel')

    previous_expiration = @user.subscription.expired_at.to_i

    VCR.use_cassette("subscriptions_user_renew_failed") do
      post '/api/subscriptions',
           {
               subscription: {
                   plan_id: plan.id,
                   user_id: @user.id,
                   card_token: 'invalid_card_token'
               }
           }.to_json, default_headers
    end

    # Check response format & status
    assert_equal 422, response.status, "API does not return the expected status."+response.body
    assert_equal Mime::JSON, response.content_type

    # Check the error was handled
    assert_match  /No such token/, response.body

    # Check that the user's subscription has not changed
    assert_equal previous_expiration, @user.subscription.expired_at.to_i, "user's subscription has changed"
  end

end
