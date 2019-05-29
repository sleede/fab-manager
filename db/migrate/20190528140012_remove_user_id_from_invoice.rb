class RemoveUserIdFromInvoice < ActiveRecord::Migration
  def change
    remove_column :invoices, :user_id, :integer
  end
end
