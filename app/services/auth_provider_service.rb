# frozen_string_literal: true

# Provides methods for the configuration of authentication providers.
class AuthProviderService
  class << self
    def auto_configure(provider)
      auto_configure_open_id_connect(provider) if provider.providable_type == OpenIdConnectProvider.name
    end

    private

    def auto_configure_open_id_connect(provider)
      raise NoMethodError unless provider.providable

      require 'uri'

      provider.providable.post_logout_redirect_uri = "#{ENV.fetch('DEFAULT_PROTOCOL')}://#{ENV.fetch('DEFAULT_HOST')}/sessions/sign_out"
      provider.providable.client__redirect_uri =
        "#{ENV.fetch('DEFAULT_PROTOCOL')}://#{ENV.fetch('DEFAULT_HOST')}/users/auth/#{provider.strategy_name}/callback"
      provider.providable.display = 'page'
      provider.providable.response_mode = 'query'
      provider.providable.response_type = 'code'
      provider.providable.uid_field = provider.auth_provider_mappings
                                              .find { |m| m.local_model == 'user' && m.local_field == 'uid' }
                                              .api_field

      URI.parse(provider.providable.issuer).tap do |uri|
        provider.providable.client__scheme = uri.scheme
        provider.providable.client__host = uri.host
        provider.providable.client__port = uri.port
      end
    end
  end
end
