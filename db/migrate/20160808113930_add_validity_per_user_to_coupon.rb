# frozen_string_literal:true

class AddValidityPerUserToCoupon < ActiveRecord::Migration[4.2]
  def change
    add_column :coupons, :validity_per_user, :string
  end
end
