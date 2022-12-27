# frozen_string_literal: true

# From this migration, machines can be grouped into categories
class CreateMachineCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :machine_categories do |t|
      t.string :name

      t.timestamps
    end
  end
end
