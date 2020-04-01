# frozen_string_literal:true

class CreateProjectSteps < ActiveRecord::Migration[4.2]
  def change
    create_table :project_steps do |t|
      t.text :description
      t.string :picture
      t.belongs_to :project, index: true

      t.timestamps
    end
  end
end
