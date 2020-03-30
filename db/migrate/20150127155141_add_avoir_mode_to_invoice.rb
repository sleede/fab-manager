# frozen_string_literal:true

class AddAvoirModeToInvoice < ActiveRecord::Migration[4.2]
  def change
    add_column :invoices, :avoir_mode, :string
  end
end
