# frozen_string_literal:true

class CreateStatisticIndices < ActiveRecord::Migration[4.2]
  def change
    create_table :statistic_indices do |t|
      t.string :es_type_key
      t.string :additional_field
      t.string :label

      t.timestamps
    end
  end
end
