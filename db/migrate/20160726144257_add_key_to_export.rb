class AddKeyToExport < ActiveRecord::Migration
  def change
    add_column :exports, :key, :string
  end
end
