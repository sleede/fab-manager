# frozen_string_literal: true

require_relative 'concerns/reservations_filters_concern'

# public API controller for resources of type Reservation
class OpenAPI::V1::ReservationsController < OpenAPI::V1::BaseController
  extend OpenAPI::APIDoc
  include Rails::Pagination
  include OpenAPI::V1::Concerns::ReservationsFiltersConcern
  expose_doc

  def index
    @reservations = Reservation.order(created_at: :desc)
                               .includes(slots_reservations: :slot, statistic_profile: :user)
                               .references(:statistic_profiles)

    @reservations = filter_by_after(@reservations, params)
    @reservations = filter_by_before(@reservations, params)
    @reservations = filter_by_user(@reservations, params)
    @reservations = filter_by_reservable_type(@reservations, params)
    @reservations = filter_by_reservable_id(@reservations, params)
    @reservations = filter_by_availability_id(@reservations, params)

    @reservations = @reservations.page(page).per(per_page)
    paginate @reservations, per_page: per_page
  end

  private

  def page
    params[:page] || 1
  end

  def per_page
    params[:per_page] || 20
  end
end
