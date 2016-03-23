class CreateStatisticIndices < ActiveRecord::Migration
  def change
    create_table :statistic_indices do |t|
      t.string :es_type_key
      t.string :additional_field
      t.string :label

      t.timestamps
    end
  end
end
