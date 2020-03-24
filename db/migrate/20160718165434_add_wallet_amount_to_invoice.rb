# frozen_string_literal:true

class AddWalletAmountToInvoice < ActiveRecord::Migration[4.2]
  def change
    add_column :invoices, :wallet_amount, :integer
  end
end
