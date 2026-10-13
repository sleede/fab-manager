# frozen_string_literal: true

require 'test_helper'

class NotificationsTest < ActionDispatch::IntegrationTest
  test 'Index lists all notifications if user has no notifications preferences' do
    @member = User.find(4)
    login_as(@member, scope: :user)

    get '/api/notifications'

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the list items are ok
    # ! Only works if notifications fixtures for this user are < NOTIFICATIONS_PER_PAGE (See NotificationsController#index)
    notifications_total = json_response(response.body)[:totals][:total]

    assert_not_equal notifications.count, 0
    assert_equal Notification.where(receiver_id: @member.id).count, notifications_total
  end

  test 'Index filters notifications if user has preferences for in_system notifications set to false' do
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)

    get '/api/notifications'

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the list items are ok
    notifications_total = json_response(response.body)[:totals][:total]
    assert_not_equal notifications.count, 0

    assert_equal NotificationPreference.where(user_id: @admin.id, in_system: false).count, 1
    assert_equal (Notification.where(receiver_id: @admin.id).count - 1), notifications_total
  end

  test 'polling endpoint' do
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)

    get '/api/notifications/polling', params: { last_poll: Notification.order(:created_at).pick(:created_at) }

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the list items are ok
    notifications_total = json_response(response.body)[:totals][:total]
    assert_not_equal notifications.count, 0
  end

  test 'Last unread returns last 3 unread notifications' do
    @member = User.find(4)
    login_as(@member, scope: :user)

    transaction1 = WalletService.new(user: @member, wallet: @member.wallet).credit(1)
    transaction2 = WalletService.new(user: @member, wallet: @member.wallet).credit(2)
    transaction3 = WalletService.new(user: @member, wallet: @member.wallet).credit(4)

    get '/api/notifications/last_unread'

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the list items are ok
    # Beware that the order of last unread notifications is descending,
    # Since the last created will be the first to appear.
    last_notifications = json_response(response.body)[:notifications]
    assert_equal last_notifications[0][:attached_object][:id], transaction3.id
    assert_equal last_notifications[1][:attached_object][:id], transaction2.id
    assert_equal last_notifications[2][:attached_object][:id], transaction1.id
  end

  test 'update marks a notification as read' do
    @member = User.find(4)
    login_as(@member, scope: :user)

    transaction = WalletService.new(user: @member, wallet: @member.wallet).credit(1)

    notification = Notification.where(receiver_id: @member.id).last
    assert_equal notification.attached_object_id, transaction.id
    assert_equal notification.is_read, false

    patch "/api/notifications/#{notification.id}"

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the list items are ok
    updated_notification = json_response(response.body)

    assert_equal updated_notification[:attached_object][:id], transaction.id
    assert_equal updated_notification[:is_read], true
  end

  test 'update_all marks all notification as read' do
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)

    patch '/api/notifications'

    # Check response format & status
    assert_equal 204, response.status, response.body

    notifications = Notification.where(receiver_id: @admin.id)

    notifications.each do |notification|
      assert_equal true, notification.is_read
    end
  end

  # ==========================================
  # FM-04: XSS & HTML injection prevention in notifications
  # ==========================================
  test 'FM-04: notification description escapes malicious payload in member name without active DOM nodes' do
    admin = User.find_by(username: 'admin')
    member = User.find(7)
    member.profile.update!(
      first_name: '<svg/onload=void(0)>',
      last_name: '<img src=x onerror=alert(1)>'
    )

    doc = SupportingDocumentFile.create!(
      supportable: member,
      supporting_document_type: SupportingDocumentType.first || SupportingDocumentType.create!(name: 'ID'),
      attachment: File.open(Rails.root.join('test/fixtures/files/document.pdf'))
    )

    NotificationCenter.call(
      type: 'notify_admin_user_supporting_document_files_updated',
      receiver: admin,
      attached_object: doc
    )

    login_as(admin, scope: :user)
    get '/api/notifications'
    assert_response :ok

    json = json_response(response.body)
    notif = json[:notifications].find do |n|
      n[:notification_type] == 'notify_admin_user_supporting_document_files_updated' &&
        n[:attached_object][:id] == doc.id
    end
    assert_not_nil notif, 'Expected supporting document notification in admin notifications list'

    description = notif[:message][:description]
    assert_match(/&lt;svg\/onload=void\(0\)&gt;/i, description)
    assert_match(/&lt;img src=x onerror=alert\(1\)&gt;/i, description)
    refute_match(/<svg\/onload=void\(0\)>/i, description)
    refute_match(/<img src=x onerror=alert\(1\)>/i, description)

    fragment = Nokogiri::HTML::DocumentFragment.parse(description)
    assert_empty fragment.css('svg'), 'Expected no active <svg> elements'
    assert_empty fragment.css('img'), 'Expected no active <img> elements'
    assert_empty fragment.css('script'), 'Expected no active <script> elements'
    assert_empty fragment.xpath('.//*[@onload or @onerror]'), 'Expected no onload/onerror event attributes'
    assert fragment.css('strong').any?, 'Expected legitimate <strong> tag preserved'
    assert fragment.css('em').any?, 'Expected legitimate <em> tag preserved'

    doc.destroy
  end

  test 'FM-04: project collaborator notification safely escapes malicious project name and user name' do
    author = User.find(7)
    collaborator = User.find(8)
    collaborator.profile.update!(first_name: 'Evil', last_name: '<script>alert("user")</script>')

    project = Project.first
    orig_name = project.name
    project.update_columns(name: '<script>alert("project")</script>')

    project_user = ProjectUser.create!(
      project: project,
      user: collaborator,
      is_valid: true
    )

    NotificationCenter.call(
      type: 'notify_project_author_when_collaborator_valid',
      receiver: author,
      attached_object: project_user
    )

    login_as(author, scope: :user)
    get '/api/notifications'
    assert_response :ok

    json = json_response(response.body)
    notif = json[:notifications].find do |n|
      n[:notification_type] == 'notify_project_author_when_collaborator_valid' &&
        n[:attached_object][:id] == project_user.id
    end
    assert_not_nil notif, 'Expected collaborator notification in author notifications'

    description = notif[:message][:description]
    fragment = Nokogiri::HTML::DocumentFragment.parse(description)
    assert_empty fragment.css('script'), 'Expected no <script> tag executed'
    link = fragment.css('a').first
    assert_not_nil link, 'Expected <a> link to project'
    assert_equal "/#!/projects/#{project.slug}", link['href']
    assert_includes link.text, '<script>alert("project")</script>'
    assert_match(/<script>alert\("user"\)<\/script>/i, fragment.text)

    project_user.destroy
    project.update_columns(name: orig_name)
  end

  test 'FM-04: ApplicationHelper#_t escapes string interpolations for html keys and preserves template tags' do
    helper = Object.new.extend(ApplicationHelper)
    res = helper._t(
      'api.notifications.notify_admin_user_merged.user_NAME_has_merged_his_account_with_the_one_imported_from_PROVIDER_UID_html',
      {
        NAME: '<svg/onload=void(0)>',
        GENDER: :male,
        PROVIDER: 'db',
        UID: '10'
      }
    )
    assert res.html_safe?, 'Expected html key result to be html_safe'
    assert_includes res, '&lt;svg/onload=void(0)&gt;'
    refute_includes res, '<svg/onload=void(0)>'
    assert_includes res, '<strong><em>'
  end

  test 'FM-04: ApplicationHelper#_t preserves plain text without pre-escaping for non-html keys' do
    helper = Object.new.extend(ApplicationHelper)
    res = helper._t(
      'api.notifications.undefined_notification.notification_ID_wrong_type_TYPE_unknown',
      {
        ID: 'A&B <Shop>',
        TYPE: 1
      }
    )
    refute res.html_safe?, 'Expected non-html key result not to be html_safe'
    assert_includes res, 'A&B <Shop>'
    refute_includes res, 'A&amp;B &lt;Shop&gt;'
  end

  test 'FM-04: legitimate names with ampersands and accents are rendered without double escaping' do
    admin = User.find_by(username: 'admin')
    member = User.find(7)
    member.profile.update!(
      first_name: 'Alice & Bob',
      last_name: "L'Étoile"
    )

    doc = SupportingDocumentFile.create!(
      supportable: member,
      supporting_document_type: SupportingDocumentType.first || SupportingDocumentType.create!(name: 'ID'),
      attachment: File.open(Rails.root.join('test/fixtures/files/document.pdf'))
    )

    NotificationCenter.call(
      type: 'notify_admin_user_supporting_document_files_updated',
      receiver: admin,
      attached_object: doc
    )

    login_as(admin, scope: :user)
    get '/api/notifications'
    assert_response :ok

    json = json_response(response.body)
    notif = json[:notifications].find do |n|
      n[:notification_type] == 'notify_admin_user_supporting_document_files_updated' &&
        n[:attached_object][:id] == doc.id
    end
    assert_not_nil notif

    description = notif[:message][:description]
    fragment = Nokogiri::HTML::DocumentFragment.parse(description)
    assert_includes fragment.text, 'Alice & Bob'
    assert_match(/L'étoile/i, fragment.text)
    refute_includes description, '&amp;amp;'

    doc.destroy
  end

  test 'FM-04: reservation limit reached notification escapes malicious limitable item name' do
    member = User.find(7)
    machine = Machine.first
    orig_name = machine.name
    machine.update_columns(name: '<img src=x onerror=alert("machine")>')

    plan = Plan.first
    limitation = PlanLimitation.find_or_create_by!(plan: plan, limitable: machine) do |pl|
      pl.limit = 5
    end

    NotificationType.find_or_create_by!(name: 'notify_member_reservation_limit_reached', category: 'agenda', is_configurable: false)

    NotificationCenter.call(
      type: 'notify_member_reservation_limit_reached',
      receiver: member,
      attached_object: limitation,
      meta_data: { date: Date.current }
    )

    login_as(member, scope: :user)
    get '/api/notifications'
    assert_response :ok

    json = json_response(response.body)
    notif = json[:notifications].find do |n|
      n[:notification_type] == 'notify_member_reservation_limit_reached' &&
        n[:attached_object][:id] == limitation.id
    end
    assert_not_nil notif

    description = notif[:message][:description]
    assert_includes description, '&lt;img src=x onerror=alert(&quot;machine&quot;)&gt;'
    refute_includes description, '<img src=x onerror=alert("machine")>'

    fragment = Nokogiri::HTML::DocumentFragment.parse(description)
    assert_empty fragment.css('img'), 'Expected no <img> elements'
    assert_empty fragment.xpath('.//*[@onerror]'), 'Expected no onerror attributes'
    assert_includes fragment.text, '<img src=x onerror=alert("machine")>'

    machine.update_columns(name: orig_name)
  end

  test 'FM-04: multi-locale notification rendering properly escapes dynamic variables across locales' do
    admin = User.find_by(username: 'admin')
    member = User.find(7)
    member.profile.update!(first_name: 'Evil', last_name: '<svg/onload=void(0)>')

    doc = SupportingDocumentFile.create!(
      supportable: member,
      supporting_document_type: SupportingDocumentType.first || SupportingDocumentType.create!(name: 'ID'),
      attachment: File.open(Rails.root.join('test/fixtures/files/document.pdf'))
    )

    NotificationCenter.call(
      type: 'notify_admin_user_supporting_document_files_updated',
      receiver: admin,
      attached_object: doc
    )

    login_as(admin, scope: :user)

    expected_texts = {
      'en' => 'Supporting document changed by member',
      'fr' => 'a modifié un justificatif',
      'es' => 'Documento justificativo modificado por el miembro'
    }

    %w[en fr es].each do |loc|
      get '/api/notifications', params: { locale: loc }
      assert_response :ok

      json = json_response(response.body)
      notif = json[:notifications].find do |n|
        n[:notification_type] == 'notify_admin_user_supporting_document_files_updated' &&
          n[:attached_object][:id] == doc.id
      end
      assert_not_nil notif, "Expected notification in locale #{loc}"

      description = notif[:message][:description]
      fragment = Nokogiri::HTML::DocumentFragment.parse(description)
      assert_empty fragment.css('svg'), "Expected no <svg> element in locale #{loc}"
      assert_empty fragment.xpath('.//*[@onload]'), "Expected no onload attribute in locale #{loc}"
      assert_match(/&lt;svg\/onload=void\(0\)&gt;/i, description)
      assert_includes description, expected_texts[loc], "Expected locale #{loc} text in description"
      assert_equal 1, fragment.css('strong').size
    end

    doc.destroy
  end
end
