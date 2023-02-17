# frozen_string_literal: true

# From this migration, we save the pending prepaid-packs in database, instead of just creating them on the fly
class CreateCartItemPrepaidPack < ActiveRecord::Migration[5.2]
  def change
    create_table :cart_item_prepaid_packs do |t|
      t.references :prepaid_pack, foreign_key: true
      t.references :customer_profile, foreign_key: { to_table: 'invoicing_profiles' }

      t.timestamps
    end
  end
end
