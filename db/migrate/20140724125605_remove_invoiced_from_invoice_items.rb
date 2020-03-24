# frozen_string_literal:true

class RemoveInvoicedFromInvoiceItems < ActiveRecord::Migration[4.2]
  def change
    remove_column :invoice_items, :invoiced_id, :integer
    remove_column :invoice_items, :invoiced_type, :string
  end
end
