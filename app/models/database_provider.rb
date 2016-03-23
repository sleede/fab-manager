class DatabaseProvider < ActiveRecord::Base
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
