# frozen_string_literal: true

# authorized 3rd party softwares can fetch data about plans through the OpenAPI
class OpenAPI::V1::PlansController < OpenAPI::V1::BaseController
  extend OpenAPI::APIDoc
  expose_doc

  before_action :set_plan, only: %i[show]

  def index
    @plans = Plan.order(:created_at)
  end

  def show; end

  private

  def set_plan
    @plan = Plan.friendly.find(params[:id])
  end
end
