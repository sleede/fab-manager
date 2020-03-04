# frozen_string_literal: true
require 'version'

# API Controller to get the Fab-manager version
class API::VersionController < API::ApiController
  before_action :authenticate_user!

  def show
    authorize :version
    update_status = Setting.find_by(name: 'hub_last_version')&.value || '{}'

    json = JSON.parse(update_status)
    json['current'] = Version.current
    render json: json, status: :ok
  end
end
