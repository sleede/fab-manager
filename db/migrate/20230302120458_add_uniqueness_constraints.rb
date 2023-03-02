# frozen_string_literal: true

# Add uniqueness constraint at database level
class AddUniquenessConstraints < ActiveRecord::Migration[5.2]
  def change
    add_index :credits, %i[plan_id creditable_id creditable_type], unique: true
    add_index :prices, %i[plan_id priceable_id priceable_type group_id duration], unique: true,
                                                                                  name: 'index_prices_on_plan_priceable_group_and_duration'
    add_index :price_categories, :name, unique: true
    add_index :auth_providers, :name, unique: true
  end
end
