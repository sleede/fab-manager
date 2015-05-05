class CreateProjectsComponents < ActiveRecord::Migration
  def change
    create_table :projects_components do |t|
      t.belongs_to :project, index: true, foreign_key: true
      t.belongs_to :component, index: true, foreign_key: true
    end
  end
end
