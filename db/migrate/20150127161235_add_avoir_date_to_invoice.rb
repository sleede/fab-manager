# frozen_string_literal:true

class AddAvoirDateToInvoice < ActiveRecord::Migration[4.2]
  def change
    add_column :invoices, :avoir_date, :datetime
  end
end
