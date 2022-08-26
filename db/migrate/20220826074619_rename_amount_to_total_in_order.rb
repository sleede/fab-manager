class RenameAmountToTotalInOrder < ActiveRecord::Migration[5.2]
  def change
    rename_column :orders, :amount, :total
  end
end
