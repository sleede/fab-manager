class AddExtensionToExport < ActiveRecord::Migration
  def change
    add_column :exports, :extension, :string, default: 'xlsx'
  end
end
