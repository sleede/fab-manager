# frozen_string_literal: true

# From this migration, we save the pending payment schedules in database, instead of just creating them on the fly
class CreateCartItemPaymentSchedule < ActiveRecord::Migration[5.2]
  def change
    create_table :cart_item_payment_schedules do |t|
      t.references :plan, foreign_key: true
      t.references :coupon, foreign_key: true
      t.boolean :requested
      t.datetime :start_at
      t.references :customer_profile, foreign_key: { to_table: 'invoicing_profiles' }

      t.timestamps
    end
  end
end
