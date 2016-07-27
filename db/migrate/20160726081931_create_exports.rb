class CreateExports < ActiveRecord::Migration
  def change
    create_table :exports do |t|
      t.string :category
      t.string :type
      t.string :query

      t.timestamps null: false
    end
  end
end
