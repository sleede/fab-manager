# frozen_string_literal:true

# Create Wallets, which are a way to virtually save money for users
class CreateWallets < ActiveRecord::Migration[4.2]
  def up
    create_table :wallets do |t|
      t.belongs_to :user, index: true, foreign_key: true
      t.integer :amount, default: 0

      t.timestamps null: false
    end

    # create all wallets
    execute <<-SQL.squish
      INSERT INTO wallets (user_id, amount, created_at, updated_at)
      SELECT users.id, 0, '#{Time.current.iso8601}', '#{Time.current.iso8601}'
      FROM users
    SQL
  end

  def down
    drop_table :wallets
  end
end
