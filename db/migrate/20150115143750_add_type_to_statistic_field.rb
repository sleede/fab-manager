class AddTypeToStatisticField < ActiveRecord::Migration
  def change
    add_column :statistic_fields, :type, :string
  end
end
