class AddReferenceToInvoice < ActiveRecord::Migration
  def change
    add_column :invoices, :reference, :string
  end
end
