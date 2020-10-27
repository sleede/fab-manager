# frozen_string_literal: true

# Save the id of the Stripe::Price associated with the current plan.
# This is used for payment schedules
class AddStpPriceIdToPlan < ActiveRecord::Migration[5.2]
  def change
    add_column :plans, :stp_price_id, :string
  end
end
