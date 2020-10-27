# frozen_string_literal: true

# Save each due dates for RepaymentSchedules
class CreateRepaymentScheduleItems < ActiveRecord::Migration[5.2]
  def change
    create_table :repayment_schedule_items do |t|
      t.integer :amount
      t.datetime :due_date
      t.belongs_to :repayment_schedule, foreign_key: true

      t.timestamps
    end
  end
end
