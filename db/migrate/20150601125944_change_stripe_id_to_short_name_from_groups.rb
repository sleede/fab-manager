class ChangeStripeIdToShortNameFromGroups < ActiveRecord::Migration
  def change
    rename_column :groups, :stripe_id, :short_name
  end
end
