require 'test_helper'

class WalletTest < ActiveSupport::TestCase
  test "default amount must be zero" do
    w = Wallet.new
    assert w.amount == 0
  end

  test 'should user present' do
    w = Wallet.create
    assert w.errors[:user].present?
  end
end
