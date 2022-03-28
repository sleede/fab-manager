# frozen_string_literal: true

# This migration allow configuration of OpenID Connect providers
class CreateOpenIdConnectProviders < ActiveRecord::Migration[5.2]
  def change
    create_table :open_id_connect_providers do |t|
      t.string :issuer
      t.boolean :discovery
      t.string :client_auth_method
      t.string :scope
      t.string :response_type
      t.string :response_type
      t.string :response_mode
      t.string :display
      t.string :prompt
      t.boolean :send_scope_to_token_endpoint
      t.string :post_logout_redirect_uri
      t.string :uid_field
      t.string :extra_authorize_params
      t.string :allow_authorize_params
      t.string :client_identifier
      t.string :client_secret
      t.string :client_redirect_uri
      t.string :client_scheme
      t.string :client_host
      t.string :client_port
      t.string :client_authorization_endpoint
      t.string :client_token_endpoint
      t.string :client_userinfo_endpoint
      t.string :client_jwks_uri
      t.string :client_end_session_endpoint

      t.timestamps
    end
  end
end
