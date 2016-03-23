class CreateInvoiceItems < ActiveRecord::Migration
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
