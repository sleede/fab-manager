class AddAvoirModeToInvoice < ActiveRecord::Migration
  def change
    add_column :invoices, :avoir_mode, :string
  end
end
