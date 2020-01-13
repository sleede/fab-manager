# frozen_string_literal: true

# Controller for the application status, useful for debugging
class HealthController < ActionController::Base
  respond_to :json

  def status
    render json: {
      name: 'Fab-Manager',
      status: 'running',
      dependencies: {
        postgresql: HealthService.database?,
        redis: HealthService.redis?,
        elasticsearch: HealthService.elasticsearch?
      },
      stats: HealthService.stats
    }
  end
end