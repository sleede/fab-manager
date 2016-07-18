class AddWalletAmountToInvoice < ActiveRecord::Migration
  def change
    add_column :invoices, :wallet_amount, :integer
  end
end
