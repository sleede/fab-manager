class AddOperatorToInvoice < ActiveRecord::Migration
  def change
    add_column :invoices, :operator_id, :integer
    add_foreign_key :invoices, :users, column: :operator_id, primary_key: :id
  end
end
