# frozen_string_literal:true

class RemoveInvoicingDisabledFromUser < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :invoicing_disabled, :boolean
  end
end
