class OpenAPI::V1::TrainingsController < OpenAPI::V1::BaseController
  extend OpenAPI::ApiDoc
  expose_doc

  def index
    @trainings = Training.order(:created_at)
  end
end
