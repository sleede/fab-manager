class CreateInvoicingProfiles < ActiveRecord::Migration
  def change
    create_table :invoicing_profiles do |t|
      t.references :user, index: true, foreign_key: true
      t.string :first_name
      t.string :last_name
      t.string :email

      t.timestamps null: false
    end

    add_reference :organizations, :invoicing_profile, index: true, foreign_key: true
    add_reference :invoices, :invoicing_profile, index: true, foreign_key: true
    add_reference :wallets, :invoicing_profile, index: true, foreign_key: true
    add_reference :wallet_transactions, :invoicing_profile, index: true, foreign_key: true
    add_reference :history_values, :invoicing_profile, index: true, foreign_key: true
  end
end
