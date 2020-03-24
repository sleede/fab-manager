# frozen_string_literal:true

class AddStateToProject < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :state, :string
    Project.all.each do |p|
      p.update_columns(state: 'published')
    end
  end
end
