# frozen_string_literal: true

# AuthProviderMapping defines the relationship between a database field (saving user's data)
# and an external API, that is authorized through an external SSO (like oAuth 2.0).
class AuthProviderMapping < ApplicationRecord
  belongs_to :auth_provider
end
