# frozen_string_literal: true

# This migration saves the scopes of the OAuth2 provider to the database.
# Previously, the scopes were defined in the OAUTH2_SCOPE environment variable.
class AddScopesToOAuth2Provider < ActiveRecord::Migration[5.2]
  def change
    add_column :o_auth2_providers, :scopes, :string
  end
end
