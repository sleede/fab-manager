# frozen_string_literal: true

require 'test_helper'

class PasswordUpdateTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    @member = User.where.not(id: @admin.id).where(provider: nil).first
    # Ensure known initial password for tests
    @initial_password = 'ValidPassword123!'
    @member.update!(password: @initial_password, password_confirmation: @initial_password)
  end

  test 'user cannot change password with password alone omitting confirmation' do
    login_as(@member, scope: :user)

    put "/api/members/#{@member.id}", params: {
      user: {
        password: 'NewSecretPass123!'
      }
    }.to_json, headers: default_headers

    assert_response :unprocessable_entity
    errors = json_response(response.body)
    assert errors[:password_confirmation].present?, 'Must reject missing password_confirmation'
    refute @member.reload.valid_password?('NewSecretPass123!'), 'Password must not change'
    assert @member.valid_password?(@initial_password), 'Original password must remain valid'
  end

  test 'user cannot change password when password_confirmation does not match' do
    login_as(@member, scope: :user)

    put "/api/members/#{@member.id}", params: {
      user: {
        password: 'NewSecretPass123!',
        password_confirmation: 'MismatchedPass123!'
      }
    }.to_json, headers: default_headers

    assert_response :unprocessable_entity
    errors = json_response(response.body)
    assert errors[:password_confirmation].present?, 'Must reject mismatched password_confirmation'
    refute @member.reload.valid_password?('NewSecretPass123!')
  end

  test 'user cannot change password when current_password is missing' do
    login_as(@member, scope: :user)

    put "/api/members/#{@member.id}", params: {
      user: {
        password: 'NewSecretPass123!',
        password_confirmation: 'NewSecretPass123!'
      }
    }.to_json, headers: default_headers

    assert_response :unprocessable_entity
    errors = json_response(response.body)
    assert errors[:current_password].present?, 'Must require current_password'
    refute @member.reload.valid_password?('NewSecretPass123!')
  end

  test 'user cannot change password when current_password is incorrect' do
    login_as(@member, scope: :user)

    put "/api/members/#{@member.id}", params: {
      user: {
        password: 'NewSecretPass123!',
        password_confirmation: 'NewSecretPass123!',
        current_password: 'WrongPassword123!'
      }
    }.to_json, headers: default_headers

    assert_response :unprocessable_entity
    errors = json_response(response.body)
    assert errors[:current_password].present?, 'Must reject invalid current_password'
    refute @member.reload.valid_password?('NewSecretPass123!')
  end

  test 'user successfully changes password with correct current_password and matching confirmation' do
    login_as(@member, scope: :user)

    put "/api/members/#{@member.id}", params: {
      user: {
        password: 'NewSecretPass123!',
        password_confirmation: 'NewSecretPass123!',
        current_password: @initial_password
      }
    }.to_json, headers: default_headers

    assert_response :ok
    assert @member.reload.valid_password?('NewSecretPass123!'), 'Password must be successfully updated'
  end

  test 'admin can reset another member password without member current_password' do
    login_as(@admin, scope: :user)

    put "/api/members/#{@member.id}", params: {
      user: {
        password: 'AdminResetPass123!',
        password_confirmation: 'AdminResetPass123!'
      }
    }.to_json, headers: default_headers

    assert_response :ok
    assert @member.reload.valid_password?('AdminResetPass123!'), 'Admin must be able to reset member password'
  end

  test 'admin updating own password requires current_password verification' do
    admin_initial_password = 'AdminOldPass123!'
    @admin.update!(password: admin_initial_password, password_confirmation: admin_initial_password)

    login_as(@admin, scope: :user)

    # Admin omitting current_password on own account should fail
    put "/api/members/#{@admin.id}", params: {
      user: {
        password: 'AdminNewPass123!',
        password_confirmation: 'AdminNewPass123!'
      }
    }.to_json, headers: default_headers

    assert_response :unprocessable_entity
    errors = json_response(response.body)
    assert errors[:current_password].present?, 'Admin self-update must require current_password'
    refute @admin.reload.valid_password?('AdminNewPass123!')

    # Admin providing correct current_password on own account should succeed
    put "/api/members/#{@admin.id}", params: {
      user: {
        password: 'AdminNewPass123!',
        password_confirmation: 'AdminNewPass123!',
        current_password: admin_initial_password
      }
    }.to_json, headers: default_headers

    assert_response :ok
    assert @admin.reload.valid_password?('AdminNewPass123!')
  end

  test 'SSO account cannot change password via local member update' do
    sso_user = User.where.not(id: [@admin.id, @member.id]).first
    sso_user.update_columns(provider: 'oauth2', uid: 'sso_12345')

    login_as(sso_user, scope: :user)

    put "/api/members/#{sso_user.id}", params: {
      user: {
        password: 'NewSSOPass123!',
        password_confirmation: 'NewSSOPass123!',
        current_password: 'SomePassword123!'
      }
    }.to_json, headers: default_headers

    assert_response :unprocessable_entity
    errors = json_response(response.body)
    assert errors[:password].present?, 'Must reject password change for SSO user'
  end

  test 'updating profile without password fields does not trigger password validation' do
    login_as(@member, scope: :user)

    put "/api/members/#{@member.id}", params: {
      user: {
        profile_attributes: {
          first_name: 'UpdatedName',
          last_name: @member.profile.last_name
        }
      }
    }.to_json, headers: default_headers

    assert_response :ok
    assert_equal 'UpdatedName', @member.reload.profile.first_name
    assert @member.valid_password?(@initial_password)
  end
end
