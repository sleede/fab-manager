class CreateUserProfileCustomFields < ActiveRecord::Migration[5.2]
  def change
    create_table :user_profile_custom_fields do |t|
      t.belongs_to :invoicing_profile, foreign_key: true
      t.belongs_to :profile_custom_field, foreign_key: true
      t.string :value

      t.timestamps
    end
  end
end
