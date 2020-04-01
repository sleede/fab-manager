# frozen_string_literal:true

class CreateProjectsComponents < ActiveRecord::Migration[4.2]
  def change
    create_table :projects_components do |t|
    	t.belongs_to :project, index: true
    	t.belongs_to :component, index: true
    end
  end
end
