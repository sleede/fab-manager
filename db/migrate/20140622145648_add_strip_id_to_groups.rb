# frozen_string_literal:true

class AddStripIdToGroups < ActiveRecord::Migration[4.2]
  def change
    add_column :groups, :stripe_id, :string
  end
end
