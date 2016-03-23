class AddStateToProject < ActiveRecord::Migration
  def change
    add_column :projects, :state, :string
    Project.all.each do |p|
      p.update_columns(state: 'published')
    end
  end
end
