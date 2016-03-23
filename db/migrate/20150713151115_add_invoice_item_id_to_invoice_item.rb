class AddInvoiceItemIdToInvoiceItem < ActiveRecord::Migration
  def change
    add_column :invoice_items, :invoice_item_id, :integer
  end
end
