class AddInvoicingProfileToWallet < ActiveRecord::Migration
  def change
    add_reference :wallets, :invoicing_profile, index: true, foreign_key: true
    add_reference :wallet_transactions, :invoicing_profile, index: true, foreign_key: true
  end
end
