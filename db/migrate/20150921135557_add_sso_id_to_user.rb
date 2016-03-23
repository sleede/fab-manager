class AddSsoIdToUser < ActiveRecord::Migration
  def change
    add_column :users, :sso_id, :integer
  end
end
