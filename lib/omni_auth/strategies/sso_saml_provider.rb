# frozen_string_literal: true

require 'omniauth-saml'

# Authentication strategy provided trough SAML
class OmniAuth::Strategies::SsoSamlProvider < OmniAuth::Strategies::SAML
  include OmniAuth::DataMapping::Mapper
end
