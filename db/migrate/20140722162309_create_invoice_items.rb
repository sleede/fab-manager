# frozen_string_literal:true

class CreateInvoiceItems < ActiveRecord::Migration[4.2]
  def change
    create_table :invoice_items do |t|
      t.text :description
      t.belongs_to :invoice, index: true
      t.string :stp_invoice_item_id
      t.string :amount

      t.timestamps
    end
  end
end
