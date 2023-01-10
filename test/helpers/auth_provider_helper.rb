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
end
