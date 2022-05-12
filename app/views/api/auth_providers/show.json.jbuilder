# frozen_string_literal: true

json.partial! 'api/auth_providers/auth_provider', auth_provider: @provider

# OAuth 2.0

if @provider.providable_type == OAuth2Provider.name
  json.providable_attributes do
    json.extract! @provider.providable, :id, :base_url, :token_endpoint, :authorization_endpoint, :profile_url, :client_id, :client_secret, :scopes
  end
end

if @provider.providable_type == OpenIdConnectProvider.name
  json.providable_attributes do
    json.extract! @provider.providable, :id, :issuer, :discovery, :client_auth_method, :scope,
                  :prompt, :send_scope_to_token_endpoint, :client__identifier, :client__secret, :client__authorization_endpoint,
                  :client__token_endpoint, :client__userinfo_endpoint, :client__jwks_uri, :client__end_session_endpoint, :profile_url
  end
end

