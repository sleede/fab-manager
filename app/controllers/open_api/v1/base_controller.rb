class OpenAPI::V1::BaseController < ActionController::Base
  protect_from_forgery with: :null_session
  before_action :authenticate
  before_action :increment_calls_count

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from OpenAPI::ParameterError, with: :bad_request
  rescue_from ActionController::ParameterMissing, with: :bad_request

  helper_method :current_api_client

  protected
    def not_found
      render json: { errors: ["Not found"] }, status: :not_found
    end

    def bad_request
      render json: { errors: ["Bad request"] }, status: :bad_request
    end

    def authenticate
      authenticate_token || render_unauthorized
    end

    def authenticate_token
      authenticate_with_http_token do |token, options|
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
