class AddWalletAmountAndWalletTransactionIdToOrder < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :wallet_amount, :integer
    add_column :orders, :wallet_transaction_id, :integer
  end
end
