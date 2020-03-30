# frozen_string_literal:true

class RemoveDescriptionFromInvoiceItems < ActiveRecord::Migration[4.2]
  def change
    remove_column :invoice_items, :description, :string
  end
end
