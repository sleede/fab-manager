# frozen_string_literal: true

# API Controller for resources of type DoDoc Project
class API::DoDocProjectsController < API::APIController
  def index
    do_doc_projects_service = DoDocProjectsService.new
    render json: do_doc_projects_service.search(params[:q], page: params[:page], per_page: params[:per_page])
  end
end
