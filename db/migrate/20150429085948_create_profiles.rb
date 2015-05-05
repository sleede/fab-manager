class CreateProfiles < ActiveRecord::Migration
  def change
    create_table :profiles do |t|
      t.belongs_to :user, index: true, foreign_key: true
      t.string :first_name
      t.string :last_name
      t.boolean :gender
      t.date :birthday
      t.string :phone
      t.text :interest
      t.text :software_mastered
      
      t.timestamps
    end
  end
end
