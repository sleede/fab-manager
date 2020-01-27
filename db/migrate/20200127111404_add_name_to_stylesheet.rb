class AddNameToStylesheet < ActiveRecord::Migration
  def change
    add_column :stylesheets, :name, :string
  end
end
