# frozen_string_literal: true

# Allow soft destroy of machines.
# Machines with existing reservation cannot be destroyed because we need them for rebuilding invoices, statistics, etc.
# This attribute allows to make a "soft destroy" of a Machine, marking it as destroyed so it doesn't appear anymore in
# the interface (as if it was destroyed) but still lives in the database so we can use it to build data.
class AddDeletedAtToMachine < ActiveRecord::Migration[5.2]
  def change
    add_column :machines, :deleted_at, :datetime
    add_index :machines, :deleted_at
  end
end
