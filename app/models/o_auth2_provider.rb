# frozen_string_literal: true

# OAuth2Provider is a special type of AuthProvider which provides authentication through an external SSO server using
# the oAuth 2.0 protocol.
class OAuth2Provider < ApplicationRecord
  has_one :auth_provider, as: :providable, dependent: :destroy
end
