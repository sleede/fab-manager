# frozen_string_literal:true

class AddUsernameToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :username, :string, after: :id

    User.includes(:profile).each do |u|
      u.update_columns(username: u.profile.username) if u.respond_to?(:username) && !u.username?
    end

  end
end
