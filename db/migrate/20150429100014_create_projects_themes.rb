class CreateProjectsThemes < ActiveRecord::Migration
  def change
    create_table :projects_themes do |t|
      t.belongs_to :project, index: true, foreign_key: true
      t.belongs_to :theme, index: true, foreign_key: true
    end
  end
end
