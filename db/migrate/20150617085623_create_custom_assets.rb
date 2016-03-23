class CreateCustomAssets < ActiveRecord::Migration
  def change
    create_table :custom_assets do |t|
      t.string :name

      t.timestamps null: false
    end
  end
end
