# frozen_string_literal: true

# API Controller for fabAnalytics
class API::AnalyticsController < API::APIController
  before_action :authenticate_user!

  def data
    authorize :analytics

    render json: HealthService.row_stats
  end
end
