# frozen_string_literal:true

# From this migration, we add a machines_visibility parameter to plans.
# This parameter determines how far in advance subscribers can view and reserve machine slots.
class AddMachineVisibilityToPlan < ActiveRecord::Migration[5.2]
  def change
    add_column :plans, :machines_visibility, :integer
  end
end
