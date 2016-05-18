class AddWebsiteToProfile < ActiveRecord::Migration
  def change
    add_column :profiles, :website, :string
  end
end
