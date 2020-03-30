# frozen_string_literal:true

class RenameResourceEndpointFromOAuth2Mappings < ActiveRecord::Migration[4.2]
  def change
    rename_column :o_auth2_mappings, :resource_endpoint, :api_endpoint
  end
end
