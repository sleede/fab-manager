class MigrateUrlToEndpointsFromOAuth2Providers < ActiveRecord::Migration
  def change
    rename_column :o_auth2_providers, :api_url, :base_url
    rename_column :o_auth2_providers, :token_url, :token_endpoint
    rename_column :o_auth2_providers, :authorization_url, :authorization_endpoint

    remove_column :o_auth2_providers, :api_data_type, :string
  end
end
