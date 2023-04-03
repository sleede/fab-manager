# frozen_string_literal: true

# We remove the footprint columns became useless
class DropFootprintColumn < ActiveRecord::Migration[6.1]
  def change
    remove_column :invoices, :footprint, :string
    remove_column :invoice_items, :footprint, :string
    remove_column :history_values, :footprint, :string
    remove_column :payment_schedules, :footprint, :string
    remove_column :payment_schedule_items, :footprint, :string
    remove_column :payment_schedule_objects, :footprint, :string
  end
end
