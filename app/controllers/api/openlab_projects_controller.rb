# frozen_string_literal: true

# API Controller for resources of type Openlab::Projects
# Openlab::Projects are Projects shared between different instances
class API::OpenlabProjectsController < API::ApiController
  PROJECTS = Openlab::Projects.new

  def index
    render json: PROJECTS.search(params[:q], page: params[:page], per_page: params[:per_page]).response.body
  rescue StandardError
    render json: { errors: ['service unavailable'] }
  end
end
