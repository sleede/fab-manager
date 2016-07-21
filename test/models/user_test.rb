require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "must create a wallet after create user" do
    u = User.create(username: 'user', email: 'userwallet@fabmanager.com', password: 'testpassword', password_confirmation: 'testpassword',
                    profile_attributes: {first_name: 'user', last_name: 'wallet', gender: true, birthday: 18.years.ago, phone: '0123456789'} )
    assert u.wallet.present?
  end
end
