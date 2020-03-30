# frozen_string_literal:true

class AddEnvironmentToInvoice < ActiveRecord::Migration[4.2]
  def change
    add_column :invoices, :environment, :string
  end
end
