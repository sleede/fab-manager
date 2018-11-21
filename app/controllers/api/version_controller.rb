
class API::VersionController < API::ApiController
  before_action :authenticate_user!

  def show
    authorize :version
    package = File.read('package.json')
    version = JSON.parse(package)['version']
    render json: { version: version }, status: :ok
  end
end
