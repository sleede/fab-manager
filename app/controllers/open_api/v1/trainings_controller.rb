# frozen_string_literal: true

# public API controller for resources of type Training
class OpenAPI::V1::TrainingsController < OpenAPI::V1::BaseController
  extend OpenAPI::APIDoc
  expose_doc

  def index
    @trainings = Training.order(:created_at)
  end
end
