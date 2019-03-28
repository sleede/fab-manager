# frozen_string_literal: true
require 'version'

# API Controller to get the fab-manager version
class API::VersionController < API::ApiController
  before_action :authenticate_user!

  def show
    authorize :version

    render json: { version: Version.current }, status: :ok
  end
end
