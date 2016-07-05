require 'test_helper'

class WalletTransactionTest < ActiveSupport::TestCase
  test 'transaction type must be credit or debit' do
    transaction = WalletTransaction.new
    transaction.transaction_type = 'credit'
    assert transaction.valid?
    transaction.transaction_type = 'debit'
    assert transaction.valid?
    transaction.transaction_type = 'other'
    assert_not transaction.valid?
  end
end
