class AddIsMainToAssets < ActiveRecord::Migration[5.2]
  def change
    add_column :assets, :is_main, :boolean
  end
end
