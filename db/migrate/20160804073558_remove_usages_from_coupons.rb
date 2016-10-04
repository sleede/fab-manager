class RemoveUsagesFromCoupons < ActiveRecord::Migration
  def change
    remove_column :coupons, :usages, :integer
  end
end
