# frozen_string_literal:true

class RenameTypeToStatTypeFromExport < ActiveRecord::Migration[4.2]
  def change
    rename_column :exports, :type, :export_type
  end
end
