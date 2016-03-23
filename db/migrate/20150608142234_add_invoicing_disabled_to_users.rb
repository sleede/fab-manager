class AddInvoicingDisabledToUsers < ActiveRecord::Migration
  def change
    add_column :users, :invoicing_disabled, :boolean, default: false
  end
end
