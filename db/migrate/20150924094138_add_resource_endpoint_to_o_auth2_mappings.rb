# frozen_string_literal:true

class AddResourceEndpointToOAuth2Mappings < ActiveRecord::Migration[4.2]
  def change
    add_column :o_auth2_mappings, :resource_endpoint, :string
    add_column :o_auth2_mappings, :api_data_type, :string
  end
end
