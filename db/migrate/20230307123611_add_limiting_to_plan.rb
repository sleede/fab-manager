# frozen_string_literal: true

# From this migration, any subscription plan can define restrictions on the reservation of resources
class AddLimitingToPlan < ActiveRecord::Migration[5.2]
  def change
    add_column :plans, :limiting, :boolean
  end
end
