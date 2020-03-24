# frozen_string_literal:true

class ChangeStripeIdToShortNameFromGroups < ActiveRecord::Migration[4.2]
  def change
    rename_column :groups, :stripe_id, :short_name
  end
end
