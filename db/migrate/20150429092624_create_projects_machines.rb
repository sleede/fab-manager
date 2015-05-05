class CreateProjectsMachines < ActiveRecord::Migration
  def change
    create_table :projects_machines do |t|
      t.belongs_to :project, index: true, foreign_key: true
      t.belongs_to :machine, index: true, foreign_key: true
    end
  end
end
