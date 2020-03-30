# frozen_string_literal:true

class AddWalletTransactionToInvoice < ActiveRecord::Migration[4.2]
  def change
    add_reference :invoices, :wallet_transaction, index: true, foreign_key: true
  end
end
