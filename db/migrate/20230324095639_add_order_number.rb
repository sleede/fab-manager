# frozen_string_literal: true

# We now store the order number in DB, instead of generating it on every access
class AddOrderNumber < ActiveRecord::Migration[6.1]
  def change
    add_column :invoices, :order_number, :string
    add_column :payment_schedules, :order_number, :string
  end
end
