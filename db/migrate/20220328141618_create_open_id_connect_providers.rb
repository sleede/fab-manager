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
      t.string :response_mode
      t.string :display
      t.string :prompt
      t.boolean :send_scope_to_token_endpoint
      t.string :post_logout_redirect_uri
      t.string :uid_field
      t.string :client__identifier
      t.string :client__secret
      t.string :client__redirect_uri
      t.string :client__scheme
      t.string :client__host
      t.string :client__port
      t.string :client__authorization_endpoint
      t.string :client__token_endpoint
      t.string :client__userinfo_endpoint
      t.string :client__jwks_uri
      t.string :client__end_session_endpoint
      t.string :profile_url

      t.timestamps
    end
  end
end
