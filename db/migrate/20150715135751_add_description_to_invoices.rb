# frozen_string_literal:true

class AddDescriptionToInvoices < ActiveRecord::Migration[4.2]
  def change
    add_column :invoices, :description, :text
  end
end
