class CreateWalletTransactions < ActiveRecord::Migration
  def change
    create_table :wallet_transactions do |t|
      t.belongs_to :user, index: true, foreign_key: true
      t.belongs_to :wallet, index: true, foreign_key: true
      t.references :transactable, polymorphic: true, index: {name: 'index_wallet_transactions_on_transactable'}
      t.string :transaction_type
      t.integer :amount

      t.timestamps null: false
    end
  end
end
