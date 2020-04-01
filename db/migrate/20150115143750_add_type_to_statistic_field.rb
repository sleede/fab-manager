# frozen_string_literal:true

class AddTypeToStatisticField < ActiveRecord::Migration[4.2]
  def change
    add_column :statistic_fields, :type, :string
  end
end
