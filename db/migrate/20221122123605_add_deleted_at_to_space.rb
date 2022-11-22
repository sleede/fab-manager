# frozen_string_literal: true

# Allow soft destroy of spaces.
# Spaces with existing reservation cannot be destroyed because we need them for rebuilding invoices, statistics, etc.
# This attribute allows to make a "soft destroy" of a Space, marking it as destroyed so it doesn't appear anymore in
# the interface (as if it was destroyed) but still lives in the database so we can use it to build data.
class AddDeletedAtToSpace < ActiveRecord::Migration[5.2]
  def change
    add_column :spaces, :deleted_at, :datetime
    add_index :spaces, :deleted_at
  end
end
