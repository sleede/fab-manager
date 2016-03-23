require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class SsoOauth2Provider < OmniAuth::Strategies::OAuth2

      def self.active_provider
        active_provider = AuthProvider.active
        if active_provider.providable_type != OAuth2Provider.name
          raise "Trying to instantiate the wrong provider: Expected OAuth2Provider, received #{active_provider.providable_type}"
        end
        active_provider
      end

      # Strategy name.
      option :name, active_provider.strategy_name


      option :client_options, {
        :site => active_provider.providable.base_url,
        :authorize_url => active_provider.providable.authorization_endpoint,
        :token_url => active_provider.providable.token_endpoint
      }

      uid { parsed_info['user.uid'.to_sym] }

      info do
        {
            :mapping => parsed_info
        }
      end

      extra do
        {
            :raw_info => raw_info
        }
      end

      # retrieve data from various url, querying each only once
      def raw_info
        @raw_info ||= Hash.new
        unless @raw_info.size > 0
          OmniAuth::Strategies::SsoOauth2Provider.active_provider.providable.o_auth2_mappings.each do |mapping|
            unless @raw_info.has_key?(mapping.api_endpoint.to_sym)
              @raw_info[mapping.api_endpoint.to_sym] = access_token.get(mapping.api_endpoint).parsed
            end
          end
        end
        @raw_info
      end


      def parsed_info
        @parsed_info ||= Hash.new
        unless @parsed_info.size > 0
          OmniAuth::Strategies::SsoOauth2Provider.active_provider.providable.o_auth2_mappings.each do |mapping|
            @parsed_info[(mapping.local_model+'.'+mapping.local_field).to_sym] = raw_info[mapping.api_endpoint.to_sym][mapping.api_field]
          end
        end
        @parsed_info
      end

    end
  end
end