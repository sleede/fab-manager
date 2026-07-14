# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'must create wallet and profiles after create user' do
    u = User.create(username: 'user', email: 'userwallet@fabmanager.com', password: 'Testpassword1$', password_confirmation: 'Testpassword1$',
                    profile_attributes: { first_name: 'user', last_name: 'wallet', phone: '0123456789' },
                    statistic_profile_attributes: { gender: true, birthday: 18.years.ago })
    assert u.wallet.present?
    assert u.profile.present?
    assert u.invoicing_profile.present?
    assert u.statistic_profile.present?
  end

  test 'destroying a user invalidates all member exports and deletes their physical files' do
    admin = User.create!(username: 'admin_user', email: 'admin_user@fabmanager.com', password: 'Testpassword1$', password_confirmation: 'Testpassword1$',
                         profile_attributes: { first_name: 'admin', last_name: 'user', phone: '0123456789' },
                         statistic_profile_attributes: { gender: true, birthday: 18.years.ago })

    member = User.create!(username: 'member_user', email: 'member_user@fabmanager.com', password: 'Testpassword1$', password_confirmation: 'Testpassword1$',
                          profile_attributes: { first_name: 'member', last_name: 'user', phone: '0123456789' },
                          statistic_profile_attributes: { gender: true, birthday: 18.years.ago })

    # Admin creates the export
    export = Export.create!(
      category: 'users',
      export_type: 'members',
      user: admin,
      extension: 'xlsx'
    )

    file_path = Rails.root.join(export.file)
    FileUtils.mkdir_p(File.dirname(file_path))
    File.write(file_path, 'dummy content')
    assert File.exist?(file_path)

    # When the member is destroyed, the admin's export must be destroyed and its file deleted
    assert_difference 'Export.count', -1 do
      member.destroy
    end

    refute File.exist?(file_path)
  end
end
