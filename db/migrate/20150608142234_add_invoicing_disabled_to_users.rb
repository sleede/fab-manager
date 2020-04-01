# frozen_string_literal:true

class AddInvoicingDisabledToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :invoicing_disabled, :boolean, default: false
  end
end
