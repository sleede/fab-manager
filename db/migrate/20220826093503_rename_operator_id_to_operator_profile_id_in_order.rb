class RenameOperatorIdToOperatorProfileIdInOrder < ActiveRecord::Migration[5.2]
  def change
    rename_column :orders, :operator_id, :operator_profile_id
    add_index :orders, :operator_profile_id
    add_foreign_key :orders, :invoicing_profiles, column: :operator_profile_id, primary_key: :id
  end
end
