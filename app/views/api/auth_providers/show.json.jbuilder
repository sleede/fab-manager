# frozen_string_literal: true

json.partial! 'api/auth_providers/auth_provider', auth_provider: @provider

# OAuth 2.0

if @provider.providable_type == OAuth2Provider.name
  json.providable_attributes do
    json.extract! @provider.providable, :id, :base_url, :token_endpoint, :authorization_endpoint, :profile_url, :client_id, :client_secret,
                  :scopes
  end
end

if @provider.providable_type == OpenIdConnectProvider.name
  json.providable_attributes do
    json.extract! @provider.providable, :id, :issuer, :discovery, :client_auth_method,
                  :prompt, :send_scope_to_token_endpoint, :client__identifier, :client__secret, :client__authorization_endpoint,
                  :client__token_endpoint, :client__userinfo_endpoint, :client__jwks_uri, :client__end_session_endpoint, :profile_url
    json.scope @provider.providable[:scope]
    json.extra_authorize_params @provider.providable[:extra_authorize_params].to_json
  end
end

if @provider.providable_type == SamlProvider.name
  json.providable_attributes do
    json.extract! @provider.providable, :id, :sp_entity_id, :idp_sso_service_url, :profile_url, :idp_cert_fingerprint, :idp_cert, :idp_slo_service_url,
                  :authn_requests_signed, :want_assertions_signed, :sp_certificate, :sp_private_key
  end
end
