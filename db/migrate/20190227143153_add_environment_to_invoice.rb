class AddEnvironmentToInvoice < ActiveRecord::Migration
  def change
    add_column :invoices, :environment, :string
  end
end
