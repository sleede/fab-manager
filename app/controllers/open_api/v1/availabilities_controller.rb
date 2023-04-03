# frozen_string_literal: true

require_relative 'concerns/reservations_filters_concern'

# public API controller for resources of type Reservation
class OpenAPI::V1::AvailabilitiesController < OpenAPI::V1::BaseController
  extend OpenAPI::APIDoc
  include Rails::Pagination
  include OpenAPI::V1::Concerns::AvailabilitiesFiltersConcern
  expose_doc

  def index
    @availabilities = Availability.order(start_at: :desc)
                                  .includes(:slots)

    @availabilities = filter_by_after(@availabilities, params)
    @availabilities = filter_by_before(@availabilities, params)
    @availabilities = filter_by_id(@availabilities, params)
    @availabilities = filter_by_available_type(@availabilities, params)
    @availabilities = filter_by_available_id(@availabilities, params)

    @availabilities = @availabilities.page(page).per(per_page)
    paginate @availabilities, per_page: per_page
  end

  private

  def page
    params[:page] || 1
  end

  def per_page
    params[:per_page] || 20
  end
end
