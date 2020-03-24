# frozen_string_literal:true

class CreateUsersCredits < ActiveRecord::Migration[4.2]
  def change
    create_table :users_credits do |t|
      t.belongs_to :user, index: true
      t.belongs_to :credit, index: true
      t.integer :hours_used

      t.timestamps
    end
  end
end
