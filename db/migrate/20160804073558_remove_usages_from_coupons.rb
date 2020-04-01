# frozen_string_literal:true

class RemoveUsagesFromCoupons < ActiveRecord::Migration[4.2]
  def change
    remove_column :coupons, :usages, :integer
  end
end
