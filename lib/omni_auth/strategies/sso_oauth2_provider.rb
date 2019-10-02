# frozen_string_literal: true

require 'omniauth-oauth2'

module OmniAuth::Strategies
  # Authentication strategy provided trough oAuth 2.0
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


    option :client_options,
           site: active_provider.providable.base_url,
           authorize_url: active_provider.providable.authorization_endpoint,
           token_url: active_provider.providable.token_endpoint

    def callback_url
      url = Rails.application.config.action_controller.default_url_options
      "#{url[:protocol]}://#{url[:host]}#{script_name}#{callback_path}"
    end

    uid { parsed_info['user.uid'.to_sym] }

    info do
      {
        mapping: parsed_info
      }
    end

    extra do
      {
        raw_info: raw_info
      }
    end

    # retrieve data from various url, querying each only once
    def raw_info
      @raw_info ||= {}
      unless @raw_info.size.positive?
        OmniAuth::Strategies::SsoOauth2Provider.active_provider.providable.o_auth2_mappings.each do |mapping|
          unless @raw_info.key?(mapping.api_endpoint.to_sym)
            @raw_info[mapping.api_endpoint.to_sym] = access_token.get(mapping.api_endpoint).parsed
          end
        end
      end
      @raw_info
    end

    def parsed_info
      @parsed_info ||= {}
      unless @parsed_info.size.positive?
        OmniAuth::Strategies::SsoOauth2Provider.active_provider.providable.o_auth2_mappings.each do |mapping|

          if mapping.transformation
            case mapping.transformation['type']
            ## INTEGER
            when 'integer'
              @parsed_info[local_sym(mapping)] = map_integer(mapping.transformation,
                                                             mapping.api_endpoint.to_sym,
                                                             mapping.api_field)

            ## BOOLEAN
            when 'boolean'
              @parsed_info[local_sym(mapping)] = map_boolean(mapping.transformation,
                                                             mapping.api_endpoint.to_sym,
                                                             mapping.api_field)

            ## DATE
            when 'date'
              @params[local_sym(mapping)] = map_date(mapping.transformation,
                                                     mapping.api_endpoint.to_sym,
                                                     mapping.api_field)

            ## OTHER TRANSFORMATIONS (not supported)
            else
              @parsed_info[local_sym(mapping)] = raw_info[mapping.api_endpoint.to_sym][mapping.api_field]
            end

          ## NO TRANSFORMATION
          else
            @parsed_info[local_sym(mapping)] = raw_info[mapping.api_endpoint.to_sym][mapping.api_field]
          end
        end
      end
      @parsed_info
    end

    private

    def local_sym(mapping)
      (mapping.local_model + '.' + mapping.local_field).to_sym
    end

    def map_integer(transformation, api_endpoint, api_field)
      value = nil
      transformation['mapping'].each do |m|
        if m['from'] == raw_info[api_endpoint][api_field]
          value = m['to']
          break
        end
      end
      # if no transformation had set any value, return the raw value
      value || raw_info[api_endpoint.to_sym][api_field]
    end

    def map_boolean(transformation, api_endpoint, api_field)
      return false if raw_info[api_endpoint][api_field] == transformation['false_value']

      true if raw_info[api_endpoint][api_field] == transformation['true_value']
    end

    def map_date(transformation, api_endpoint, api_field)
      case transformation['format']
      when 'iso8601'
        DateTime.iso8601(raw_info[api_endpoint][api_field])
      when 'rfc2822'
        DateTime.rfc2822(raw_info[api_endpoint][api_field])
      when 'rfc3339'
        DateTime.rfc3339(raw_info[api_endpoint][api_field])
      when 'timestamp-s'
        DateTime.strptime(raw_info[api_endpoint][api_field], '%s')
      when 'timestamp-ms'
        DateTime.strptime(raw_info[api_endpoint][api_field], '%Q')
      else
        DateTime.parse(raw_info[api_endpoint][api_field])
      end
    end
  end
end
