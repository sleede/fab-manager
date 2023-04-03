# frozen_string_literal: true

require 'test_helper'

class AbusesTest < ActionDispatch::IntegrationTest
  # Abuse report
  test 'visitor report an abuse' do
    project = Project.take

    post '/api/abuses',
         params: {
           abuse: {
             signaled_type: 'Project',
             signaled_id: project.id,
             first_name: 'William',
             last_name: 'Prindle',
             email: 'wprindle@iastate.edu',
             message: 'This project is in infringement with the patent US5014921 A.'
           }
         }.to_json,
         headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the correct object was signaled
    abuse = json_response(response.body)
    assert_equal project.id, abuse[:reporting][:signaled_id], 'project ID mismatch'
    assert_equal 'Project', abuse[:reporting][:signaled_type], 'signaled object type mismatch'

    # Check notifications were sent for every admins
    notifications = Notification.where(notification_type_id: NotificationType.find_by(name: 'notify_admin_abuse_reported'),
                                       attached_object_type: 'Abuse',
                                       attached_object_id: abuse[:reporting][:id])
    assert_not_empty notifications, 'no notifications were created'
    notified_users_ids = notifications.map(&:receiver_id)
    User.admins.each do |adm|
      assert_includes notified_users_ids, adm.id, "Admin #{adm.id} was not notified"
    end
  end

  # Incomplete abuse report
  test 'visitor send an invalid report' do
    project = Project.first

    post '/api/abuses',
         params: {
           abuse: {
             signaled_type: 'Project',
             signaled_id: project.id,
             first_name: 'John',
             last_name: 'Wrong',
             email: '',
             message: ''
           }
         }.to_json,
         headers: default_headers

    assert_equal 422, response.status, response.body
    assert_match(/can't be blank/, response.body)
  end

  test 'admin list all abuses' do
    login_as(User.admins.first, scope: :user)

    get '/api/abuses'
    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the abuses
    abuses = json_response(response.body)
    assert_equal Abuse.count, abuses[:abuses].length
    assert_not_nil abuses[:abuses].first[:id]
    assert_not_nil abuses[:abuses].first[:signaled_type]
    assert_not_nil abuses[:abuses].first[:signaled_id]
    assert_not_nil abuses[:abuses].first[:first_name]
    assert_not_nil abuses[:abuses].first[:last_name]
    assert_not_nil abuses[:abuses].first[:email]
    assert_not_nil abuses[:abuses].first[:message]
    assert_not_nil abuses[:abuses].first[:created_at]
    assert_not_nil abuses[:abuses].first[:signaled]
    assert_not_nil abuses[:abuses].first[:signaled][:name]
    assert_not_nil abuses[:abuses].first[:signaled][:slug]
    assert_not_nil abuses[:abuses].first[:signaled][:published_at]
    assert_not_nil abuses[:abuses].first[:signaled][:author]
  end

  test 'admin delete an abuse' do
    login_as(User.admins.first, scope: :user)

    delete '/api/abuses/1'
    assert_response :success
    assert_empty response.body
  end
end
