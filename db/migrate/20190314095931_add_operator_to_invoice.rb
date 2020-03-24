# frozen_string_literal:true

class AddOperatorToInvoice < ActiveRecord::Migration[4.2]
  def change
    add_column :invoices, :operator_id, :integer
    add_foreign_key :invoices, :users, column: :operator_id, primary_key: :id
  end
end
