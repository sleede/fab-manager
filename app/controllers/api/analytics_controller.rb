# frozen_string_literal: true

# API Controller for fabAnalytics
class API::AnalyticsController < API::ApiController
  before_action :authenticate_user!

  def data
    render json: HealthService.row_stats
  end
end
