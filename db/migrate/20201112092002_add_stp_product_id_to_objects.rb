# frozen_string_literal: true

# Save the id of the Stripe::Product associated with the current plan or reservable object.
# This is used for payment schedules.
# Machines, Trainings and Spaces can be reserved jointly with a subscription that can have a
# payment schedule, so we must associate them with Stripe::Product.
# This is not the case for Events (we can't buy event+subscription) so we dot no associate a
# Stripe::Product with the events.
class AddStpProductIdToObjects < ActiveRecord::Migration[5.2]
  def change
    add_column :plans, :stp_product_id, :string
    add_column :machines, :stp_product_id, :string
    add_column :spaces, :stp_product_id, :string
    add_column :trainings, :stp_product_id, :string
  end
end
