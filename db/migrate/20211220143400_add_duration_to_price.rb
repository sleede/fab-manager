# frozen_string_literal: true

# From this migration, we allow Prices to be configured by duration.
# For example, a Price for a 30-minute session could be configured to be twice the price of a 60-minute session.
# This is useful for things like "half-day" sessions, or full-day session when the price is different than the default hour-based price.
class AddDurationToPrice < ActiveRecord::Migration[5.2]
  def change
    add_column :prices, :duration, :integer, default: 60
  end
end
