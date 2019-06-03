class RemoveUserIdFromWallet < ActiveRecord::Migration
  def change
    remove_reference :wallets, :user, index: true, foreign_key: true
    remove_reference :wallet_transactions, :user, index: true, foreign_key: true
  end
end
