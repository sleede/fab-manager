# frozen_string_literal: true

# From this migration, we migrate the chaining system to the new chained_elements table
class MigrateChainingSystem < ActiveRecord::Migration[6.1]
  def up
    [Invoice, InvoiceItem, HistoryValue, PaymentSchedule, PaymentScheduleItem, PaymentScheduleObject].each do |klass|
      order = klass == HistoryValue ? :created_at : :id
      previous = nil
      klass.order(order).find_each do |item|
        created = ChainedElement.create!(
          element: item,
          previous: previous
        )
        previous = created
      end
    end
  end

  def down
    execute("TRUNCATE TABLE #{ChainedElement.arel_table.name}")
  end
end
