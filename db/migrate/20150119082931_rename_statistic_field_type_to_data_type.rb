# frozen_string_literal:true

class RenameStatisticFieldTypeToDataType < ActiveRecord::Migration[4.2]
  def change
    rename_column :statistic_fields, :type, :data_type
  end
end
