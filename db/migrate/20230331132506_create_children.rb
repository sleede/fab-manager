# frozen_string_literal: true

# Child is a modal for a child of a user
class CreateChildren < ActiveRecord::Migration[5.2]
  def change
    create_table :children do |t|
      t.belongs_to :user, foreign_key: true
      t.string :first_name
      t.string :last_name
      t.date :birthday
      t.string :phone
      t.string :email

      t.timestamps
    end
  end
end
