class CreateInvoices < ActiveRecord::Migration
  def change
    create_table :invoices do |t|
      t.references :invoiced,  polymorphic: true
      t.string :stp_invoice_id
      t.integer :total

      t.timestamps
    end
  end
end
