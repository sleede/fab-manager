# frozen_string_literal:true

# From this migration, each machine can belongs to a MachineCategory
class AddMachineCategoryIdToMachine < ActiveRecord::Migration[5.2]
  def change
    add_reference :machines, :machine_category, index: true, foreign_key: true
  end
end
