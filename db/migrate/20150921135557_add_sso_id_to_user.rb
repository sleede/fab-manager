# frozen_string_literal:true

class AddSsoIdToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :sso_id, :integer
  end
end
