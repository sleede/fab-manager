class CreateProfiles < ActiveRecord::Migration
  def change
    create_table :profiles do |t|
      t.belongs_to :user, index: true
      t.string :username
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
