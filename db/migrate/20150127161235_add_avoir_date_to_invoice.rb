class AddAvoirDateToInvoice < ActiveRecord::Migration
  def change
    add_column :invoices, :avoir_date, :datetime
  end
end
