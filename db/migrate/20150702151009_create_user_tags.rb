# frozen_string_literal:true

class CreateUserTags < ActiveRecord::Migration[4.2]
  def change
    create_table :user_tags do |t|
      t.belongs_to :user, index: true, foreign_key: true
      t.belongs_to :tag, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
