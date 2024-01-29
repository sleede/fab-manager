# frozen_string_literal: true

require 'omniauth-saml'
require_relative '../data_mapping/mapper'

# Authentication strategy provided trough SAML
class OmniAuth::Strategies::SsoSamlProvider < OmniAuth::Strategies::SAML
  include OmniAuth::DataMapping::Mapper

  def self.active_provider
    active_provider = Rails.configuration.auth_provider
    if active_provider.providable_type != 'SamlProvider'
      raise "Trying to instantiate the wrong provider: Expected SamlProvider, received #{active_provider.providable_type}"
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
      OmniAuth::Strategies::SsoSamlProvider.active_provider.auth_provider_mappings,
      user_info: @attributes.attributes.transform_values {|v| v.is_a?(Array) ? v.first : v  }
    )
  end
end
