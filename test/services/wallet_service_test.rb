require 'test_helper'

class WalletServiceTest < ActiveSupport::TestCase
  setup do
    @admin = User.find_by(username: 'admin')
    @jdupond = User.find_by(username: 'jdupond')
    @jdupond_wallet = @jdupond.wallet
    @vlonchamp = User.find_by(username: 'vlonchamp')
    @vlonchamp_wallet = @vlonchamp.wallet
  end

  test 'admin can credit a wallet' do
    service = WalletService.new(user: @admin, wallet: @jdupond_wallet)
    expected_amount = @jdupond_wallet.amount + 5
    assert service.credit(5)
    assert_equal @jdupond_wallet.amount, expected_amount
  end

  test 'create a credit transaction after credit amount to wallet' do
    service = WalletService.new(user: @admin, wallet: @jdupond_wallet)
    assert_equal 0, @jdupond_wallet.wallet_transactions.count
    assert service.credit(10)
    transaction = @jdupond_wallet.wallet_transactions.first
    assert_equal transaction.transaction_type, 'credit'
    assert_equal transaction.amount, 10
    assert_equal transaction.user, @admin
    assert_equal transaction.wallet, @jdupond_wallet
  end

  test 'create a debit transaction after debit amoutn to wallet' do
    service = WalletService.new(user: @vlonchamp, wallet: @vlonchamp_wallet)
    assert service.debit(5, nil)
    transaction = @vlonchamp_wallet.wallet_transactions.last
    assert_equal transaction.transaction_type, 'debit'
    assert_equal transaction.amount, 5
    assert_equal transaction.user, @vlonchamp
    assert_equal transaction.wallet, @vlonchamp_wallet
  end
end
