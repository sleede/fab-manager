# frozen_string_literal: true

# If a plan is marked as "monthly_payment", we can charge its subscriptions with a repayment schedule
# instead of a single invoice
class AddMonthlyPaymentToPlan < ActiveRecord::Migration[5.2]
  def change
    add_column :plans, :monthly_payment, :boolean
  end
end
