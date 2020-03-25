# frozen_string_literal: true

# DatabaseProvider is a special type of AuthProvider which provides the default app authentication method.
# This method uses Devise and the local database.
class DatabaseProvider < ApplicationRecord
  has_one :auth_provider, as: :providable, dependent: :destroy

  def protected_fields
    []
  end

  def profile_url
    '/#!/dashboard/profile'
  end

  def omniauth_authorize_path
    'users/sign_in'
  end
end
