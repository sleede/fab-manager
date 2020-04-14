# frozen_string_literal:true

class CreateProjectsThemes < ActiveRecord::Migration[4.2]
  def change
    create_table :projects_themes do |t|
      t.belongs_to :project, index: true
      t.belongs_to :theme, index: true
    end
  end
end
