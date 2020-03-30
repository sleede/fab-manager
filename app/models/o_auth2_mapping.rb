# frozen_string_literal: true

# OAuth2Mapping defines a database field, saving user's data, that is mapped to an external API, that is authorized
# through an external SSO of type oAuth 2
class OAuth2Mapping < ApplicationRecord
  belongs_to :o_auth2_provider
end
