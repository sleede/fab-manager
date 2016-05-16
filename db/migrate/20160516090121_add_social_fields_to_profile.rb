class AddSocialFieldsToProfile < ActiveRecord::Migration
  def change
    add_column :profiles, :facebook, :string
    add_column :profiles, :twitter, :string
    add_column :profiles, :google_plus, :string
    add_column :profiles, :viadeo, :string
    add_column :profiles, :linkedin, :string
    add_column :profiles, :instagram, :string
    add_column :profiles, :youtube, :string
    add_column :profiles, :vimeo, :string
    add_column :profiles, :dailymotion, :string
    add_column :profiles, :github, :string
    add_column :profiles, :echosciences, :string
  end
end
