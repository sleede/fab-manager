# frozen_string_literal: true

# Saves RepaymentSchedules in database.
# It allows to pay with multiple payments
class CreateRepaymentSchedules < ActiveRecord::Migration[5.2]
  def change
    create_table :repayment_schedules do |t|
      t.references :scheduled, polymorphic: true
      t.integer :total
      t.string :stp_subscription_id
      t.string :reference
      t.string :payment_method
      t.integer :wallet_amount
      t.belongs_to :wallet_transaction, foreign_key: true
      t.belongs_to :coupon, foreign_key: true
      t.string :footprint
      t.string :environment
      t.belongs_to :invoicing_profile, foreign_key: true
      t.references :operator_profile_id, foreign_key: { to_table: 'invoicing_profiles' }

      t.timestamps
    end
  end
end
