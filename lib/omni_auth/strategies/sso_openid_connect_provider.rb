# frozen_string_literal: true

require 'omniauth_openid_connect'

module OmniAuth::Strategies
  # Authentication strategy provided trough OpenID Connect
  class SsoOpenidConnectProvider < OmniAuth::Strategies::OpenIDConnect

    def self.active_provider
      active_provider = AuthProvider.active
      if active_provider.providable_type != OpenIdConnectProvider.name
        raise "Trying to instantiate the wrong provider: Expected OpenIdConnectProvider, received #{active_provider.providable_type}"
      end

      active_provider
    end

    # Strategy name.
    option :name, active_provider.strategy_name

  end
end
