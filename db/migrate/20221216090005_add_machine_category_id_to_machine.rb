# frozen_string_literal:true

class AddMachineCategoryIdToMachine < ActiveRecord::Migration[5.2]
  def change
    add_reference :machines, :machine_category, index: true, foreign_key: true
  end
end
