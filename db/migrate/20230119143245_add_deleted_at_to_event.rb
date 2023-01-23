# frozen_string_literal: true

# Allow soft destroy of events.
# Events with existing reservation cannot be destroyed because we need them for rebuilding invoices, statistics, etc.
# This attribute allows to make a "soft destroy" of an Event, marking it as destroyed so it doesn't appear anymore in
# the interface (as if it was destroyed) but still lives in the database so we can use it to build data.
class AddDeletedAtToEvent < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :deleted_at, :datetime
    add_index :events, :deleted_at
  end
end
