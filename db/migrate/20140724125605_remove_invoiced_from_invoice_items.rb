class RemoveInvoicedFromInvoiceItems < ActiveRecord::Migration
  def change
    remove_column :invoice_items, :invoiced_id, :integer
    remove_column :invoice_items, :invoiced_type, :string
  end
end
