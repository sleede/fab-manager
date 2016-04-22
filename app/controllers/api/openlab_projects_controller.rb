class API::OpenlabProjectsController < API::ApiController
  PROJECTS = Openlab::Projects.new

  def index
    begin
      render json: PROJECTS.search(params[:q], page: params[:page], per_page: params[:per_page]).response.body
    rescue Errno::ECONNREFUSED
      render json: { errors: ['service unavailable'] } and return
    end
  end
end
