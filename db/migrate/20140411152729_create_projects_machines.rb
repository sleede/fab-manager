# frozen_string_literal:true

class CreateProjectsMachines < ActiveRecord::Migration[4.2]
  def change
    create_table :projects_machines do |t|
      t.belongs_to :project, index: true
      t.belongs_to :machine, index: true
    end
  end
end
