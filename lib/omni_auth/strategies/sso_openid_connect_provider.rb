# frozen_string_literal: true

require 'omniauth_openid_connect'
require_relative '../data_mapping/mapper'

module OmniAuth::Strategies
  # Authentication strategy provided trough OpenID Connect
  class SsoOpenidConnectProvider < OmniAuth::Strategies::OpenIDConnect
    include OmniAuth::DataMapping::Mapper

    def self.active_provider
      active_provider = AuthProvider.active
      if active_provider.providable_type != OpenIdConnectProvider.name
        raise "Trying to instantiate the wrong provider: Expected OpenIdConnectProvider, received #{active_provider.providable_type}"
      end

      active_provider
    end

    # Strategy name.
    option :name, active_provider.strategy_name

    info do
      {
        mapping: parsed_info
      }
    end

    def parsed_info
      mapped_info(
        OmniAuth::Strategies::SsoOpenidConnectProvider.active_provider.auth_provider_mappings,
        user_info: user_info.raw_attributes
      )
    end
  end
end
