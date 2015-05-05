class CreateProjectUsers < ActiveRecord::Migration
  def change
    create_table :project_users do |t|
      t.belongs_to :project, index: true, foreign_key: true
      t.belongs_to :user, index: true, foreign_key: true
      t.boolean :is_valid, default: false
      t.string :valid_token

      t.timestamps
    end
  end
end
