# frozen_string_literal: true

# From this migration users can be identified by an unique external ID
class AddExternalIdToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :external_id, :string, null: true
    add_index :users, :external_id, unique: true, where: '(external_id IS NOT NULL)', name: 'unique_not_null_external_id'
  end
end
