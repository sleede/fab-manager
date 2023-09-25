class AddSpaceIdToMachines < ActiveRecord::Migration[7.0]
  def change
    add_reference :machines, :space, foreign_key: true, index: true
  end
end
