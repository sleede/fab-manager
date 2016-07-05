require 'test_helper'

class WalletServiceTest < ActiveSupport::TestCase
  setup do
    @admin = User.find_by(username: 'admin')
    @user = User.find_by(username: 'jdupond')
    @wallet = @user.wallet
  end

  test 'admin can credit a wallet' do
    service = WalletService.new(user: @admin, wallet: @wallet)
    expected_amount = @wallet.amount + 5
    assert service.credit(5)
    assert_equal @wallet.amount, expected_amount
  end

  test 'create a credit transaction after credit amount to wallet' do
    service = WalletService.new(user: @admin, wallet: @wallet)
    assert_equal 0, @wallet.wallet_transactions.count
    assert service.credit(10)
    transaction = @wallet.wallet_transactions.first
    assert_equal transaction.transaction_type, 'credit'
    assert_equal transaction.amount, 10
    assert_equal transaction.user, @admin
    assert_equal transaction.wallet, @wallet
  end
end
