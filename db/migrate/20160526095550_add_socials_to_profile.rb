class AddSocialsToProfile < ActiveRecord::Migration
  def change
    add_column :profiles, :pinterest, :string
    add_column :profiles, :lastfm, :string
    add_column :profiles, :flickr, :string
  end
end
