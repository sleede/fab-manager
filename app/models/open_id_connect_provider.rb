# frozen_string_literal: true

# OpenIdConnectProvider is a special type of AuthProvider which provides authentication through an external SSO server using
# the OpenID Connect protocol.
class OpenIdConnectProvider < ApplicationRecord
  has_one :auth_provider, as: :providable
end
