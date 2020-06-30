# frozen_string_literal: true

# API Controller for resources of type Openlab::Projects
# Openlab::Projects are Projects shared between different instances
class API::OpenlabProjectsController < API::ApiController
  before_action :init_openlab

  def index
    render json: @projets.search(params[:q], page: params[:page], per_page: params[:per_page]).response.body
  rescue StandardError
    render json: { errors: ['service unavailable'] }
  end

  private

  def init_openlab
    client = Openlab::Client.new(app_secret: Setting.get('openlab_app_secret'))
    @projets = Openlab::Projects.new(client)
  end
end
