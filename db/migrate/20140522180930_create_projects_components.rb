class CreateProjectsComponents < ActiveRecord::Migration
  def change
    create_table :projects_components do |t|
    	t.belongs_to :project, index: true
    	t.belongs_to :component, index: true
    end
  end
end
