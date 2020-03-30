# frozen_string_literal:true

class AddInvoicedToInvoiceItems < ActiveRecord::Migration[4.2]
  def change
    add_column :invoice_items, :invoiced_id, :integer
    add_column :invoice_items, :invoiced_type, :string
  end
end
