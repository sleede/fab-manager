# frozen_string_literal: true

# From this migration, the machines will be able to appear in the list, but without being reservable
class AddReservableToMachine < ActiveRecord::Migration[5.2]
  def change
    add_column :machines, :reservable, :boolean, default: true
  end
end
