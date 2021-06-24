# frozen_string_literal: true

# module definition
module OpenAPI::V1; end

# Parameters for OpenAPI endpoints
class OpenAPI::V1::BaseController < ActionController::Base
  protect_from_forgery with: :null_session
  skip_before_action :verify_authenticity_token
  before_action :authenticate
  before_action :increment_calls_count

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from OpenAPI::ParameterError, with: :bad_request
  rescue_from ActionController::ParameterMissing, with: :bad_request

  rescue_from TypeError, with: :server_error
  rescue_from NoMethodError, with: :server_error
  rescue_from ArgumentError, with: :server_error

  helper_method :current_api_client

  protected

  def not_found(exception)
    render json: { errors: ['Not found', exception] }, status: :not_found
  end

  def bad_request(exception)
    render json: { errors: ['Bad request', exception] }, status: :bad_request
  end

  def server_error(exception)
    render json: { error: ['Server error', exception] }, status: :internal_server_error
  end

  def authenticate
    authenticate_token || render_unauthorized
  end

  def authenticate_token
    authenticate_with_http_token do |token, _options|
      @open_api_client = OpenAPI::Client.find_by(token: token)
    end
  end

  def current_api_client
    @open_api_client
  end

  def render_unauthorized
    render json: { errors: ['Bad credentials'] }, status: 401
  end

  private

  def increment_calls_count
    @open_api_client.increment_calls_count
  end
end
