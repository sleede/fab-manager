# frozen_string_literal: true

# From this migration, we save in database the "feature tours" viewed by each users to prevent displaying them many times
class AddToursToProfile < ActiveRecord::Migration
  def change
    add_column :profiles, :tours, :string
  end
end
