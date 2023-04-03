# frozen_string_literal: true

# authorized 3rd party softwares can fetch data about plan categories through the OpenAPI
class OpenAPI::V1::PlanCategoriesController < OpenAPI::V1::BaseController
  extend OpenAPI::APIDoc
  expose_doc

  def index
    @plans_categories = PlanCategory.order(:created_at)
  end
end
