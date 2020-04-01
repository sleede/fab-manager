# frozen_string_literal:true

class AddSocialsToProfile < ActiveRecord::Migration[4.2]
  def change
    add_column :profiles, :pinterest, :string
    add_column :profiles, :lastfm, :string
    add_column :profiles, :flickr, :string
  end
end
