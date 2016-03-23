class MigrateEndpointsToUrlsFromOAuth2Providers < ActiveRecord::Migration
  def change
    rename_column :o_auth2_providers, :base_url, :api_url
    rename_column :o_auth2_providers, :token_endpoint, :token_url
    rename_column :o_auth2_providers, :authorization_endpoint, :authorization_url
    add_column :o_auth2_providers, :api_data_type, :string
  end
end
