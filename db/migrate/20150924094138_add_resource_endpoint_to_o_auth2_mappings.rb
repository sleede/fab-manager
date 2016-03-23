class AddResourceEndpointToOAuth2Mappings < ActiveRecord::Migration
  def change
    add_column :o_auth2_mappings, :resource_endpoint, :string
    add_column :o_auth2_mappings, :api_data_type, :string
  end
end
