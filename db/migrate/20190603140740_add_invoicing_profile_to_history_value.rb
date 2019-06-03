class AddInvoicingProfileToHistoryValue < ActiveRecord::Migration
  def change
    add_reference :history_values, :invoicing_profile, index: true, foreign_key: true
  end
end
