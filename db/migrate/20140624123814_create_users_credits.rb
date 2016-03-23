class CreateUsersCredits < ActiveRecord::Migration
  def change
    create_table :users_credits do |t|
      t.belongs_to :user, index: true
      t.belongs_to :credit, index: true
      t.integer :hours_used

      t.timestamps
    end
  end
end
