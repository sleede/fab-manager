# frozen_string_literal:true

class CreateProjectUser < ActiveRecord::Migration[4.2]
  def change
    create_table :project_users do |t|
      t.belongs_to :project, index: true
      t.belongs_to :user, index: true

      t.timestamps
    end
  end
end
