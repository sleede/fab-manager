# frozen_string_literal: true

# public API controller for resources of type Price
class OpenAPI::V1::PricesController < OpenAPI::V1::BaseController
  extend OpenAPI::APIDoc
  include Rails::Pagination
  expose_doc

  def index
    @prices = PriceService.list(params).order(created_at: :desc)

    return if params[:page].blank?

    @prices = @prices.page(params[:page]).per(per_page)
    paginate @prices, per_page: per_page
  end

  private

  def per_page
    params[:per_page] || 20
  end
end
