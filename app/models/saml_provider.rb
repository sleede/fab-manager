# frozen_string_literal: true

# SAML Provider is a special type of AuthProvider which provides authentication through an external SSO server using
# the SAML protocol.

class SamlProvider < ApplicationRecord
  has_one :auth_provider, as: :providable, dependent: :destroy

  validates :sp_entity_id, presence: true
  validates :idp_sso_service_url, presence: true
end
