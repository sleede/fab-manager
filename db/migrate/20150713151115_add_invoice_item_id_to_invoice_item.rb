# frozen_string_literal:true

class AddInvoiceItemIdToInvoiceItem < ActiveRecord::Migration[4.2]
  def change
    add_column :invoice_items, :invoice_item_id, :integer
  end
end
