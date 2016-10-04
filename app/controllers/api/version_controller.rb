
class API::VersionController < API::ApiController
  before_action :authenticate_user!

  def show
    authorize :version
    version = File.read('.fabmanager-version')
    render json: {version: version}, status: :ok
  end
end