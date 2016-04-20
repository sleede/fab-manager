class AbusesTest < ActionDispatch::IntegrationTest

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    # Do nothing
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  # Abuse report
  test 'visitor report an abuse' do
    project = Project.take

    post '/api/abuses',
         {
             abuse: {
                 signaled_type: 'Project',
                 signaled_id: project.id,
                 first_name: 'William',
                 last_name: 'Prindle',
                 email: 'wprindle@iastate.edu',
                 message: 'This project is in infringement with the patent US5014921 A.'
             }
         }.to_json,
         default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_equal Mime::JSON, response.content_type

    # Check the correct object was signaled
    abuse = json_response(response.body)
    assert_equal project.id, abuse[:reporting][:signaled_id], 'project ID mismatch'
    assert_equal 'Project', abuse[:reporting][:signaled_type], 'signaled object type mismatch'

    # Check notifications were sent for every admins
    notifications = Notification.where(notification_type_id: NotificationType.find_by_name('notify_admin_abuse_reported'), attached_object_type: 'Abuse', attached_object_id: abuse[:reporting][:id])
    assert_not_empty notifications, 'no notifications were created'
    notified_users_ids = notifications.map {|n| n.receiver_id }
    User.admins.each do |adm|
      assert_includes notified_users_ids, adm.id, "Admin #{adm.id} was not notified"
    end
  end

  # Incomplete abuse report
  test 'visitor send an invalid report' do
    project = Project.first

    post '/api/abuses',
         {
             abuse: {
                 signaled_type: 'Project',
                 signaled_id: project.id,
                 first_name: 'John',
                 last_name: 'Wrong',
                 email: '',
                 message: ''
             }
         }.to_json,
         default_headers

    assert_equal 422, response.status, response.body
    assert_match /can't be blank/, response.body
  end

end
