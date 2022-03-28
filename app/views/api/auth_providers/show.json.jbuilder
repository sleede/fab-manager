# frozen_string_literal: true

json.partial! 'api/auth_providers/auth_provider', auth_provider: @provider

# OAuth 2.0

if @provider.providable_type == OAuth2Provider.name
  json.providable_attributes do
    json.extract! @provider.providable, :id, :base_url, :token_endpoint, :authorization_endpoint, :profile_url, :client_id, :client_secret, :scopes
  end
end
