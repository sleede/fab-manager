class CreateProfileCustomFields < ActiveRecord::Migration[5.2]
  def change
    create_table :profile_custom_fields do |t|
      t.string :label
      t.boolean :required, default: false
      t.boolean :actived, default: false

      t.timestamps
    end
  end
end
