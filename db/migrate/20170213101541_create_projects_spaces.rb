class CreateProjectsSpaces < ActiveRecord::Migration
  def change
    create_table :projects_spaces do |t|
      t.belongs_to :project, index: true, foreign_key: true
      t.belongs_to :space, index: true, foreign_key: true
    end
  end
end
