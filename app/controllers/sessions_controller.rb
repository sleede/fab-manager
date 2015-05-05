class SessionsController < Devise::SessionsController
  #before_action :set_csrf_headers, only: [:create, :destroy]

  protected
  def set_csrf_headers
    cookies['XSRF-TOKEN'] = form_authenticity_token if protect_against_forgery?
  end
end
