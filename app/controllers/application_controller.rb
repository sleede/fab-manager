class ApplicationController < ActionController::Base
  include Pundit
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  after_action :set_csrf_cookie
  cache_sweeper :stylesheet_sweeper

  respond_to :html, :json

  before_action :configure_permitted_parameters, if: :devise_controller?

  # Globally rescue Authorization Errors in controller.
  # Returning 403 Forbidden if permission is denied
  rescue_from Pundit::NotAuthorizedError, with: :permission_denied

  def index
  end

  protected
  def set_csrf_cookie
    cookies['XSRF-TOKEN'] = form_authenticity_token if protect_against_forgery?
  end

  def verified_request?
    super || valid_authenticity_token?(session, request.headers['X-XSRF-TOKEN'])
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) <<
      {profile_attributes: [:phone, :last_name, :first_name,
        :gender, :birthday, :interest, :software_mastered,
        organization_attributes: [:name, address_attributes: [:address]]]}
    devise_parameter_sanitizer.for(:sign_up).concat [:username, :is_allow_contact, :is_allow_newsletter, :cgu, :group_id]
  end

  def default_url_options
    { :host => Rails.application.secrets.default_host, protocol: Rails.application.secrets.default_protocol }
  end

  def permission_denied
    head 403
  end
end
