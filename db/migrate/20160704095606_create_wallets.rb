# frozen_string_literal:true

class CreateWallets < ActiveRecord::Migration[4.2]
  def up
    create_table :wallets do |t|
      t.belongs_to :user, index: true, foreign_key: true
      t.integer :amount, default: 0

      t.timestamps null: false
    end

    User.all.each do |u|
      Wallet.create(user: u)
    end
  end

  def down
    drop_table :wallets
  end
end
