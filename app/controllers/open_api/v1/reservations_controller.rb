# frozen_string_literal: true

# public API controller for resources of type Reservation
class OpenAPI::V1::ReservationsController < OpenAPI::V1::BaseController
  extend OpenAPI::ApiDoc
  include Rails::Pagination
  expose_doc

  def index
    @reservations = Reservation.order(created_at: :desc)
                               .includes(statistic_profile: :user)
                               .references(:statistic_profiles)

    @reservations = @reservations.where(statistic_profiles: { user_id: params[:user_id] }) if params[:user_id].present?
    @reservations = @reservations.where(reservable_type: format_type(params[:reservable_type])) if params[:reservable_type].present?
    @reservations = @reservations.where(reservable_id: params[:reservable_id]) if params[:reservable_id].present?

    return unless params[:page].present?

    @reservations = @reservations.page(params[:page]).per(per_page)
    paginate @reservations, per_page: per_page
  end

  private

  def format_type(type)
    type.singularize.classify
  end

  def per_page
    params[:per_page] || 20
  end
end
