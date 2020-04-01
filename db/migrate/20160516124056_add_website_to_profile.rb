# frozen_string_literal:true

class AddWebsiteToProfile < ActiveRecord::Migration[4.2]
  def change
    add_column :profiles, :website, :string
  end
end
