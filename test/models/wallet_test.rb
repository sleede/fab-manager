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

  test 'can credit amount' do
    w = Wallet.first
    expected_amount = w.amount + 5.5
    assert w.credit(5.5)
    assert_equal w.amount, expected_amount
  end

  test 'can debit amount' do
    w = Wallet.first
    w.credit(5)
    expected_amount = w.amount - 5
    assert w.debit(5)
    assert_equal w.amount, expected_amount
  end

  test 'cant debit/credit a negative' do
    w = Wallet.new
    assert_not w.credit(-5)
    assert_not w.debit(-5)
  end

  test 'wallet amount cant < 0 after debit' do
    w = Wallet.new
    assert_not w.debit(5)
  end
end
