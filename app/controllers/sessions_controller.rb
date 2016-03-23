class SessionsController < Devise::SessionsController
  #before_action :set_csrf_headers, only: [:create, :destroy]

  def new
    active_provider = AuthProvider.active
    if active_provider.providable_type != DatabaseProvider.name
      redirect_to user_omniauth_authorize_path(active_provider.strategy_name.to_sym)
    else
      super
    end
  end

  protected
  def set_csrf_headers
    cookies['XSRF-TOKEN'] = form_authenticity_token if protect_against_forgery?
  end
end
