# frozen_string_literal: true

# From this migration, we save the pending coupons in database, instead of just creating them on the fly
class CreateCartItemCoupon < ActiveRecord::Migration[5.2]
  def change
    create_table :cart_item_coupons do |t|
      t.references :coupon, foreign_key: true
      t.references :customer_profile, foreign_key: { to_table: 'invoicing_profiles' }
      t.references :operator_profile, foreign_key: { to_table: 'invoicing_profiles' }

      t.timestamps
    end
  end
end
