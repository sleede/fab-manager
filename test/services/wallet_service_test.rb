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
    expected_amount = @jdupond_wallet.amount + 10
    assert_equal 0, @jdupond_wallet.wallet_transactions.count
    transaction = service.credit(10)
    @jdupond_wallet.reload
    assert transaction
    assert_equal @jdupond_wallet.amount, expected_amount
    assert_equal transaction.transaction_type, 'credit'
    assert_equal transaction.amount, 10
    assert_equal transaction.user, @admin
    assert_equal transaction.wallet, @jdupond_wallet
  end

  test 'create a debit transaction after debit amount to wallet' do
    service = WalletService.new(user: @vlonchamp, wallet: @vlonchamp_wallet)
    expected_amount = @vlonchamp_wallet.amount - 5
    transaction = service.debit(5, nil)
    @vlonchamp_wallet.reload
    assert transaction
    assert_equal @vlonchamp_wallet.amount, expected_amount
    assert_equal transaction.transaction_type, 'debit'
    assert_equal transaction.amount, 5
    assert_equal transaction.user, @vlonchamp
    assert_equal transaction.wallet, @vlonchamp_wallet
  end

  test 'dont debit amount > wallet amount' do
    service = WalletService.new(user: @vlonchamp, wallet: @vlonchamp_wallet)
    expected_amount = @vlonchamp_wallet.amount
    service.debit(100, nil)
    @vlonchamp_wallet.reload
    assert_equal @vlonchamp_wallet.amount, expected_amount
  end

  test 'rollback debited amount if has an error when create wallet transaction' do
    service = WalletService.new(wallet: @vlonchamp_wallet)
    expected_amount = @vlonchamp_wallet.amount
    transaction = service.debit(5, nil)
    @vlonchamp_wallet.reload
    assert_equal @vlonchamp_wallet.amount, expected_amount
    assert_not transaction
  end
end
