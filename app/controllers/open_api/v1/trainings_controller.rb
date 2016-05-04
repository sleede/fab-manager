class OpenAPI::V1::TrainingsController < OpenAPI::V1::BaseController
  def index
    @trainings = Training.order(:created_at)
  end
end
