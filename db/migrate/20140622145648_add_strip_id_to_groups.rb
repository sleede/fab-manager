class AddStripIdToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :stripe_id, :string
  end
end
