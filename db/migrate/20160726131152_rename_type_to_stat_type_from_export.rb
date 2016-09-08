class RenameTypeToStatTypeFromExport < ActiveRecord::Migration
  def change
    rename_column :exports, :type, :export_type
  end
end
