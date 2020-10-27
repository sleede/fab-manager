# frozen_string_literal:true

class CreateInvoices < ActiveRecord::Migration[4.2]
  def change
    create_table :invoices do |t|
      t.references :invoiced, polymorphic: true
      t.string :stp_invoice_id
      t.integer :total

      t.timestamps
    end
  end
end
