class RenameResourceEndpointFromOAuth2Mappings < ActiveRecord::Migration
  def change
    rename_column :o_auth2_mappings, :resource_endpoint, :api_endpoint
  end
end
