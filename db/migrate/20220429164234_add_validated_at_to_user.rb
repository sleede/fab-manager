class AddValidatedAtToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :validated_at, :datetime
  end
end
