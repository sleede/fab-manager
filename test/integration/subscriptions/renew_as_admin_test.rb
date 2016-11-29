class Subscriptions::RenewAsAdminTest < ActionDispatch::IntegrationTest

  setup do
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'admin successfully renew a subscription before it has ended' do

    user = User.find_by(username: 'kdumas')
    plan = Plan.find_by(base_name: 'Mensuel tarif réduit')

    VCR.use_cassette("subscriptions_admin_renew_success") do
      post '/api/subscriptions',
           {
               subscription: {
                   plan_id: plan.id,
                   user_id: user.id
               }
           }.to_json, default_headers
    end

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_equal Mime::JSON, response.content_type

    # Check the correct plan was subscribed
    subscription = json_response(response.body)
    assert_equal plan.id, subscription[:plan_id], 'subscribed plan does not match'

    # Check that the user has the correct subscription
    assert_not_nil user.subscription, "user's subscription was not found"
    assert_not_nil user.subscription.plan, "user's subscribed plan was not found"
    assert_equal plan.id, user.subscription.plan_id, "user's plan does not match"

    # Check that the training credits were set correctly
    assert_empty user.training_credits, 'training credits were not reset'
    assert_equal user.subscription.plan.training_credit_nb, plan.training_credit_nb, 'trainings credits were not allocated'

    # Check that the user benefit from prices of his plan
    printer = Machine.find_by(slug: 'imprimante-3d')
    assert_equal 10, (printer.prices.find_by(group_id: user.group_id, plan_id: user.subscription.plan_id).amount / 100), 'machine hourly price does not match'

    # Check notification was sent to the user
    notification = Notification.find_by(notification_type_id: NotificationType.find_by_name('notify_member_subscribed_plan'), attached_object_type: 'Subscription', attached_object_id: subscription[:id])
    assert_not_nil notification, 'user notification was not created'
    assert_equal user.id, notification.receiver_id, 'wrong user notified'

    # Check generated invoice
    invoice = Invoice.find_by(invoiced_type: 'Subscription', invoiced_id: subscription[:id])
    assert_invoice_pdf invoice
    assert_equal plan.amount, invoice.total, 'Invoice total price does not match the bought subscription'

  end

end