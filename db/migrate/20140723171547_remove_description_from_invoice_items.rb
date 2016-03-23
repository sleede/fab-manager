class RemoveDescriptionFromInvoiceItems < ActiveRecord::Migration
  def change
    remove_column :invoice_items, :description, :string
  end
end
