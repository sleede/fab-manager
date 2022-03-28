# frozen_string_literal: true

require 'omniauth-oauth2'
require 'jsonpath'
require 'sso_logger'

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

    def authorize_params
      super.tap do |params|
        params[:scope] = active_provider.providable.scopes
      end
    end

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
      logger = SsoLogger.new

      @raw_info ||= {}
      logger.debug "[raw_info] @raw_infos = #{@raw_info&.to_json}"
      unless @raw_info.size.positive?
        OmniAuth::Strategies::SsoOauth2Provider.active_provider.auth_provider_mappings.each do |mapping|
          logger.debug "mapping = #{mapping&.to_json}"
          next if @raw_info.key?(mapping.api_endpoint.to_sym)

          logger.debug "api_endpoint = #{mapping.api_endpoint.to_sym}"
          logger.debug "access_token = #{access_token&.to_json}"
          logger.debug "token get = #{access_token.get(mapping.api_endpoint)}"
          logger.debug "parsed = #{access_token.get(mapping.api_endpoint).parsed}"
          @raw_info[mapping.api_endpoint.to_sym] = access_token.get(mapping.api_endpoint).parsed
        end
      end
      @raw_info
    end

    def parsed_info
      logger = SsoLogger.new

      @parsed_info ||= {}
      logger.debug "[parsed_info] @parsed_info = #{@parsed_info.to_json}"
      unless @parsed_info.size.positive?
        OmniAuth::Strategies::SsoOauth2Provider.active_provider.auth_provider_mappings.each do |mapping|

          raw_data = ::JsonPath.new(mapping.api_field).on(raw_info[mapping.api_endpoint.to_sym]).first
          logger.debug "@parsed_info[#{local_sym(mapping)}] mapped from #{raw_data}"
          if mapping.transformation
            case mapping.transformation['type']
            ## INTEGER
            when 'integer'
              @parsed_info[local_sym(mapping)] = map_integer(mapping.transformation, raw_data)

            ## BOOLEAN
            when 'boolean'
              @parsed_info[local_sym(mapping)] = map_boolean(mapping.transformation, raw_data)

            ## DATE
            when 'date'
              @params[local_sym(mapping)] = map_date(mapping.transformation, raw_data)

            ## OTHER TRANSFORMATIONS (not supported)
            else
              @parsed_info[local_sym(mapping)] = raw_data
            end

          ## NO TRANSFORMATION
          else
            @parsed_info[local_sym(mapping)] = raw_data
          end
        end
      end
      @parsed_info
    end

    private

    def local_sym(mapping)
      (mapping.local_model + '.' + mapping.local_field).to_sym
    end

    def map_integer(transformation, raw_data)
      value = nil
      transformation['mapping'].each do |m|
        if m['from'] == raw_data
          value = m['to']
          break
        end
      end
      # if no transformation had set any value, return the raw value
      value || raw_data
    end

    def map_boolean(transformation, raw_data)
      return false if raw_data == transformation['false_value']

      true if raw_data == transformation['true_value']
    end

    def map_date(transformation, raw_data)
      case transformation['format']
      when 'iso8601'
        DateTime.iso8601(raw_data)
      when 'rfc2822'
        DateTime.rfc2822(raw_data)
      when 'rfc3339'
        DateTime.rfc3339(raw_data)
      when 'timestamp-s'
        DateTime.strptime(raw_data, '%s')
      when 'timestamp-ms'
        DateTime.strptime(raw_data, '%Q')
      else
        DateTime.parse(raw_data)
      end
    end
  end
end
