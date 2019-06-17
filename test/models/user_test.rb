# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'must create wallet and profiles after create user' do
    u = User.create(username: 'user', email: 'userwallet@fabmanager.com', password: 'testpassword', password_confirmation: 'testpassword',
                    profile_attributes: { first_name: 'user', last_name: 'wallet', phone: '0123456789' },
                    statistic_profile_attributes: { gender: true, birthday: 18.years.ago })
    assert u.wallet.present?
    assert u.profile.present?
    assert u.invoicing_profile.present?
    assert u.statistic_profile.present?
  end
end
