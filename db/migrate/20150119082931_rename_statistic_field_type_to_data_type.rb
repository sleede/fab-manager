class RenameStatisticFieldTypeToDataType < ActiveRecord::Migration
  def change
    rename_column :statistic_fields, :type, :data_type
  end
end
