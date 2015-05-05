class CreateProjectSteps < ActiveRecord::Migration
  def change
    create_table :project_steps do |t|
      t.text :description
      t.string :title
      t.belongs_to :project, index: true, foreign_key: true

      t.timestamps
    end
  end
end
