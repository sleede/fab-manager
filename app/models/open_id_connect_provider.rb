# frozen_string_literal: true

# OpenIdConnectProvider is a special type of AuthProvider which provides authentication through an external SSO server using
# the OpenID Connect protocol.
class OpenIdConnectProvider < ApplicationRecord
  has_one :auth_provider, as: :providable, dependent: :destroy

  validates :issuer, presence: true
  validates :client__identifier, presence: true
  validates :client__secret, presence: true
  validates :client__host, presence: true
  validates :client__scheme, inclusion: { in: %w[http https] }
  validates :client__port, numericality: { only_integer: true, greater_than: 0, less_than: 65_535 }
  validates :response_type, inclusion: { in: %w[code id_token], allow_nil: true }
  validates :response_mode, inclusion: { in: %w[query fragment form_post web_message], allow_nil: true }
  validates :display, inclusion: { in: %w[page popup touch wap], allow_nil: true }
  validates :prompt, inclusion: { in: %w[none login consent select_account], allow_nil: true }
  validates :client_auth_method, inclusion: { in: %w[basic jwks] }
end
