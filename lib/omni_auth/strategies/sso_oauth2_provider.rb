# frozen_string_literal: true

require 'omniauth-oauth2'
require 'jsonpath'
require 'sso_logger'
require_relative '../data_mapping/mapper'

# Authentication strategy provided trough oAuth 2.0
class OmniAuth::Strategies::SsoOauth2Provider < OmniAuth::Strategies::OAuth2
  include OmniAuth::DataMapping::Mapper

  def self.active_provider
    active_provider = Rails.configuration.auth_provider
    if active_provider.providable_type != 'OAuth2Provider'
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
      params[:scope] = OmniAuth::Strategies::SsoOauth2Provider.active_provider.providable.scopes
    end
  end

  def callback_url
    url = Rails.application.config.action_controller.default_url_options
    "#{url[:protocol]}://#{url[:host]}#{script_name}#{callback_path}"
  end

  uid { parsed_info[:'user.uid'] }

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
    mapped_info(OmniAuth::Strategies::SsoOauth2Provider.active_provider.auth_provider_mappings, raw_info)
  end
end
