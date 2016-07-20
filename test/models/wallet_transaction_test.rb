require 'test_helper'

class WalletTransactionTest < ActiveSupport::TestCase
  test 'transaction type must be credit or debit' do
    @jdupond = User.find_by(username: 'jdupond')
    @jdupond_wallet = @jdupond.wallet
    transaction = WalletTransaction.new amount: 5, user: @jdupond, wallet: @jdupond_wallet
    transaction.transaction_type = 'credit'
    assert transaction.valid?
    transaction.transaction_type = 'debit'
    assert transaction.valid?
    transaction.transaction_type = 'other'
    assert_not transaction.valid?
  end
end
