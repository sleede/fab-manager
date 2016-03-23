class AddUsernameToUser < ActiveRecord::Migration
  def change
    add_column :users, :username, :string, after: :id

    User.includes(:profile).each do |u|
      if u.respond_to? :username and !u.username?
        u.update_columns(username: u.profile.username)
      end
    end

  end
end
