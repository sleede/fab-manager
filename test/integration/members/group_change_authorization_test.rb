# frozen_string_literal: true

require 'test_helper'

class GroupChangeAuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    Warden.test_reset!
    @admin = users(:user1)
    @manager = users(:user5)
    @manager.add_role :manager unless @manager.manager?

    @member = users(:user2) # jdupond (no running subscription)
    @subscriber = User.friendly.find('kdumas') # running subscription

    @group1 = Group.find(1)
    @group2 = Group.find(2)
    @disabled_group = Group.create!(name: 'Disabled Group', slug: 'disabled-group', disabled: true)

    @member.update!(group: @group1)
    Setting.set('user_change_group', false)
  end

  teardown do
    Warden.test_reset!
    Setting.set('user_change_group', true)
  end

  test 'member cannot change group when user_change_group setting is false' do
    login_as(@member, scope: :user)

    put "/api/members/#{@member.id}",
        params: { user: { group_id: @group2.id, profile_attributes: { first_name: 'HackedName' } } }.to_json,
        headers: default_headers

    assert_response :unprocessable_entity
    errors = json_response(response.body)
    assert_includes errors[:group_id], I18n.t('members.unable_to_change_group_disabled')
    assert_equal @group1.id, @member.reload.group_id
    assert_not_equal 'HackedName', @member.profile.first_name
  end

  test 'member without initial group cannot assign group when user_change_group is false' do
    @member.update_column(:group_id, nil) # rubocop:disable Rails/SkipsModelValidations
    login_as(@member, scope: :user)

    put "/api/members/#{@member.id}", params: { user: { group_id: @group2.id } }.to_json, headers: default_headers

    assert_response :unprocessable_entity
    assert_nil @member.reload.group_id
  end

  test 'member cannot change group when user_change_group setting is missing' do
    Setting.set('user_change_group', nil)
    login_as(@member, scope: :user)

    put "/api/members/#{@member.id}", params: { user: { group_id: @group2.id } }.to_json, headers: default_headers

    assert_response :unprocessable_entity
    assert_equal @group1.id, @member.reload.group_id
  end

  test 'member can update other profile attributes without group_id when user_change_group is false' do
    login_as(@member, scope: :user)

    put "/api/members/#{@member.id}",
        params: { user: { profile_attributes: { first_name: 'LegitNewName', last_name: @member.profile.last_name } } }.to_json,
        headers: default_headers

    assert_response :ok
    assert_equal 'LegitNewName', @member.reload.profile.first_name
    assert_equal @group1.id, @member.group_id
  end

  test 'member can submit identical group_id when user_change_group is false' do
    login_as(@member, scope: :user)

    payload = { user: { group_id: @group1.id, profile_attributes: { first_name: 'SameGroupNewName', last_name: @member.profile.last_name } } }
    put "/api/members/#{@member.id}", params: payload.to_json, headers: default_headers

    assert_response :ok
    assert_equal 'SameGroupNewName', @member.reload.profile.first_name
    assert_equal @group1.id, @member.group_id
  end

  test 'member cannot change to non-existent group' do
    Setting.set('user_change_group', true)
    login_as(@member, scope: :user)

    put "/api/members/#{@member.id}", params: { user: { group_id: 999_999 } }.to_json, headers: default_headers

    assert_response :unprocessable_entity
    assert_equal @group1.id, @member.reload.group_id
  end

  test 'member cannot change to invalid group id format' do
    Setting.set('user_change_group', true)
    login_as(@member, scope: :user)

    ['12abc', '-5', 0, -1, '', '   '].each do |bad_id|
      put "/api/members/#{@member.id}", params: { user: { group_id: bad_id } }.to_json, headers: default_headers

      assert_response :unprocessable_entity
      assert_equal @group1.id, @member.reload.group_id
    end
  end

  test 'member cannot change to disabled group even when user_change_group is true' do
    Setting.set('user_change_group', true)
    login_as(@member, scope: :user)

    put "/api/members/#{@member.id}", params: { user: { group_id: @disabled_group.id } }.to_json, headers: default_headers

    assert_response :unprocessable_entity
    assert_equal @group1.id, @member.reload.group_id
  end

  test 'member successfully changes to active group when user_change_group is true' do
    Setting.set('user_change_group', true)
    login_as(@member, scope: :user)

    put "/api/members/#{@member.id}", params: { user: { group_id: @group2.id } }.to_json, headers: default_headers

    assert_response :ok
    assert_equal @group2.id, @member.reload.group_id
  end

  test 'member changing group requiring new supporting documents resets validation and reminder' do
    Setting.set('user_change_group', true)
    Setting.set('user_validation_required', true)

    doc_type = SupportingDocumentType.create!(name: 'Extra Requirement', document_type: 'User')
    @group2.supporting_document_types << doc_type

    validation_time = 1.day.ago.change(usec: 0)
    reminder_time = 2.days.ago.change(usec: 0)
    @member.update!(validated_at: validation_time, supporting_documents_reminder_sent_at: reminder_time)

    login_as(@member, scope: :user)

    put "/api/members/#{@member.id}", params: { user: { group_id: @group2.id } }.to_json, headers: default_headers

    assert_response :ok
    assert_equal @group2.id, @member.reload.group_id
    assert_nil @member.validated_at
    assert_nil @member.supporting_documents_reminder_sent_at
  end

  test 'member changing group without extra documents preserves validated_at' do
    Setting.set('user_change_group', true)
    Setting.set('user_validation_required', true)

    @group2.supporting_document_types.clear
    validation_time = 1.day.ago.change(usec: 0)
    @member.update!(validated_at: validation_time)

    login_as(@member, scope: :user)

    put "/api/members/#{@member.id}", params: { user: { group_id: @group2.id } }.to_json, headers: default_headers

    assert_response :ok
    assert_equal @group2.id, @member.reload.group_id
    assert_not_nil @member.validated_at
    assert_equal validation_time.to_i, @member.validated_at.to_i
  end

  test 'member with active subscription cannot change group even if user_change_group is true' do
    Setting.set('user_change_group', true)
    login_as(@subscriber, scope: :user)

    put "/api/members/#{@subscriber.id}", params: { user: { group_id: @group1.id } }.to_json, headers: default_headers

    assert_response :unprocessable_entity
    errors = json_response(response.body)
    assert_includes errors[:group_id], I18n.t('members.unable_to_change_the_group_while_a_subscription_is_running')
  end

  test 'admin can change member group when user_change_group is false' do
    login_as(@admin, scope: :user)

    put "/api/members/#{@member.id}", params: { user: { group_id: @group2.id } }.to_json, headers: default_headers

    assert_response :ok
    assert_equal @group2.id, @member.reload.group_id
  end

  test 'manager can change member group when user_change_group is false' do
    assert @manager.manager?, 'Manager fixture must have manager role'
    login_as(@manager, scope: :user)

    put "/api/members/#{@member.id}", params: { user: { group_id: @group2.id } }.to_json, headers: default_headers

    assert_response :ok
    assert_equal @group2.id, @member.reload.group_id
  end

  test 'rejected group change does not send group changed notifications' do
    notification_type = NotificationType.find_by(name: 'notify_user_user_group_changed')
    initial_count = Notification.where(notification_type: notification_type, receiver_id: @member.id).count

    login_as(@member, scope: :user)

    put "/api/members/#{@member.id}", params: { user: { group_id: @group2.id } }.to_json, headers: default_headers

    assert_response :unprocessable_entity
    assert_equal initial_count, Notification.where(notification_type: notification_type, receiver_id: @member.id).count
  end

  test 'failed update with invalid fields does not send group changed notifications' do
    Setting.set('user_change_group', true)
    notification_type = NotificationType.find_by(name: 'notify_user_user_group_changed')
    initial_count = Notification.where(notification_type: notification_type, receiver_id: @member.id).count

    login_as(@member, scope: :user)

    # Valid group switch, but invalid email format causes model update failure
    put "/api/members/#{@member.id}",
        params: { user: { group_id: @group2.id, email: 'not-an-email' } }.to_json,
        headers: default_headers

    assert_response :unprocessable_entity
    assert_equal @group1.id, @member.reload.group_id
    assert_equal initial_count, Notification.where(notification_type: notification_type, receiver_id: @member.id).count
  end
end
