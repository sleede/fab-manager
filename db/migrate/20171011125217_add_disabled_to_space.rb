class AddDisabledToSpace < ActiveRecord::Migration
  def change
    add_column :spaces, :disabled, :boolean
  end
end
