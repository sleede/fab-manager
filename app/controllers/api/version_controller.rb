# frozen_string_literal: true

require 'version'

# API Controller to get the Fab-manager version
class API::VersionController < API::APIController
  before_action :authenticate_user!

  def show
    authorize :version
    # save the origin
    origin = Setting.find_or_create_by(name: 'origin')
    if origin.value != params[:origin]
      origin.value = params[:origin]
      origin.save!
    end
    # get the last version
    update_status = Setting.get('hub_last_version') || '{}'

    json = JSON.parse(update_status)
    json['current'] = Version.current
    render json: json, status: :ok
  end
end
