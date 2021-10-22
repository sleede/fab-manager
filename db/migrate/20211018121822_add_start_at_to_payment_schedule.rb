# frozen_string_literal: true

# From this migration, we allow PaymentSchedules to start later, previously the started
# as soon as they were created.
class AddStartAtToPaymentSchedule < ActiveRecord::Migration[5.2]
  def change
    add_column :payment_schedules, :start_at, :datetime
  end
end
