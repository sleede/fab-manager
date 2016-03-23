class AddInvoicedToInvoiceItems < ActiveRecord::Migration
  def change
    add_column :invoice_items, :invoiced_id, :integer
    add_column :invoice_items, :invoiced_type, :string
  end
end
