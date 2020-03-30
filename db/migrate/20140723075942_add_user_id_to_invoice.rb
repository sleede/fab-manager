# frozen_string_literal:true

class AddUserIdToInvoice < ActiveRecord::Migration[4.2]
  def change
    add_reference :invoices, :user, index: true
  end
end
