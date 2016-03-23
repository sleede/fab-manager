class CreateAssets < ActiveRecord::Migration
  def change
    create_table :assets do |t|
      t.references :viewable,  polymorphic: true
      t.string :attachment
      t.string :type

      t.timestamps
    end
  end
end
