class AddWalletTransactionToInvoice < ActiveRecord::Migration
  def change
    add_reference :invoices, :wallet_transaction, index: true, foreign_key: true
  end
end
