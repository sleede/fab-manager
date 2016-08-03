class CreateCoupons < ActiveRecord::Migration
  def change
    create_table :coupons do |t|
      t.string :name
      t.string :code
      t.integer :percent_off
      t.datetime :valid_until
      t.integer :max_usages
      t.integer :usages
      t.boolean :active
      t.string :stp_coupon_id

      t.timestamps null: false
    end
  end
end
