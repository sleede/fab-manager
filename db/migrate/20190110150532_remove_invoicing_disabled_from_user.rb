class RemoveInvoicingDisabledFromUser < ActiveRecord::Migration
  def change
    remove_column :users, :invoicing_disabled, :boolean
  end
end
