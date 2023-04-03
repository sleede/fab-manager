# frozen_string_literal: true

# Provides methods to help authentication providers
module AuthProviderHelper
  def github_provider_params(name)
    {
      name: name,
      providable_type: 'OAuth2Provider',
      providable_attributes: {
        authorization_endpoint: 'authorize',
        token_endpoint: 'access_token',
        base_url: 'https://github.com/login/oauth/',
        profile_url: 'https://github.com/settings/profile',
        client_id: ENV.fetch('OAUTH_CLIENT_ID', 'github-oauth-app-id'),
        client_secret: ENV.fetch('OAUTH_CLIENT_SECRET', 'github-oauth-app-secret')
      },
      auth_provider_mappings_attributes: [
        {
          api_data_type: 'json',
          api_endpoint: 'https://api.github.com/user',
          api_field: 'id',
          local_field: 'uid',
          local_model: 'user'
        },
        {
          api_data_type: 'json',
          api_endpoint: 'https://api.github.com/user',
          api_field: 'html_url',
          local_field: 'github',
          local_model: 'profile'
        }
      ]
    }
  end

  def keycloak_provider_params(name)
    {
      name: name,
      providable_type: 'OpenIdConnectProvider',
      providable_attributes: {
        issuer: 'https://sso.sleede.dev/auth/realms/master',
        discovery: true,
        client_auth_method: 'basic',
        scope: %w[openid profile email],
        prompt: 'consent',
        send_scope_to_token_endpoint: true,
        profile_url: 'https://sso.sleede.dev/auth/realms/master/account/',
        client__identifier: ENV.fetch('OIDC_CLIENT_ID', 'oidc-client-id'),
        client__secret: ENV.fetch('OIDC_CLIENT_SECRET', 'oidc-client-secret'),
        client__authorization_endpoint: '',
        client__token_endpoint: '',
        client__userinfo_endpoint: '',
        client__end_session_endpoint: ''
      },
      auth_provider_mappings_attributes: [
        { id: '', local_model: 'user', local_field: 'uid', api_endpoint: 'user_info', api_data_type: 'json', api_field: 'sub' },
        { id: '', local_model: 'user', local_field: 'email', api_endpoint: 'user_info', api_data_type: 'json', api_field: 'email' },
        { id: '', local_model: 'profile', local_field: 'first_name', api_endpoint: 'user_info', api_data_type: 'json', api_field: 'given_name' },
        { id: '', local_model: 'profile', local_field: 'last_name', api_endpoint: 'user_info', api_data_type: 'json', api_field: 'family_name' }
      ]
    }
  end
end
