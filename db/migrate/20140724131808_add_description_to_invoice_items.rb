# frozen_string_literal:true

class AddDescriptionToInvoiceItems < ActiveRecord::Migration[4.2]
  def change
    add_column :invoice_items, :description, :text
  end
end
