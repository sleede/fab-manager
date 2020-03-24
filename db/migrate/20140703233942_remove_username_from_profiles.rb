# frozen_string_literal:true

class RemoveUsernameFromProfiles < ActiveRecord::Migration[4.2]
  def change
  	remove_column :profiles, :username, :string
  end
end
