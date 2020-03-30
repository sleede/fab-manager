# frozen_string_literal:true

class RemoveUserIdColumns < ActiveRecord::Migration[4.2]
  def change
    remove_column :invoices, :user_id, :integer
    remove_reference :organizations, :profile, index: true, foreign_key: true
    remove_reference :wallets, :user, index: true, foreign_key: true
    remove_reference :wallet_transactions, :user, index: true, foreign_key: true
    remove_reference :history_values, :user, index: true, foreign_key: true
    remove_reference :invoices, :operator, index: true
  end
end
