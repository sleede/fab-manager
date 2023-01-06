# frozen_string_literal: true

# From this migration, ths object_type and object_id columns in InvoiceItem won't be able to be null anymore
# This will prevent issues while building the accounting data, and ensure data integrity
class AddNotNullToInvoiceItemsObject < ActiveRecord::Migration[5.2]
  def change
    change_column_null :invoice_items, :object_type, false
    change_column_null :invoice_items, :object_id, false
  end
end
