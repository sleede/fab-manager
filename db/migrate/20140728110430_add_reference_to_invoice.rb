# frozen_string_literal:true

class AddReferenceToInvoice < ActiveRecord::Migration[4.2]
  def change
    add_column :invoices, :reference, :string
  end
end
