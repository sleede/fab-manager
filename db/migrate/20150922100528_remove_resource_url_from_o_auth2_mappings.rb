class RemoveResourceUrlFromOAuth2Mappings < ActiveRecord::Migration
  def change
    remove_column :o_auth2_mappings, :resource_url, :string
    remove_column :o_auth2_mappings, :data_type, :string
  end
end
