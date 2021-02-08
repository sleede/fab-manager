# frozen_string_literal: true

# Save each due dates for PaymentSchedules
class CreatePaymentScheduleItems < ActiveRecord::Migration[5.2]
  def change
    create_table :payment_schedule_items do |t|
      t.integer :amount
      t.datetime :due_date
      t.string :state, default: 'new'
      t.jsonb :details, default: '{}'
      t.string :stp_invoice_id
      t.string :payment_method
      t.string :client_secret
      t.belongs_to :payment_schedule, foreign_key: true
      t.belongs_to :invoice, foreign_key: true
      t.string :footprint

      t.timestamps
    end
  end
end
