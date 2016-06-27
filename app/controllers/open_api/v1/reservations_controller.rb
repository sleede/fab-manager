class OpenAPI::V1::ReservationsController < OpenAPI::V1::BaseController
  extend OpenAPI::ApiDoc
  expose_doc

  def index
    @reservations = Reservation.order(created_at: :desc)

    if params[:user_id].present?
      @reservations = @reservations.where(user_id: params[:user_id])
    else
      @reservations = @reservations.includes(user: :profile)
    end

    if params[:reservable_type].present?
      @reservations = @reservations.where(reservable_type: format_type(params[:reservable_type]))
    end

    if params[:reservable_id].present?
      @reservations = @reservations.where(reservable_id: params[:reservable_id])
    end

    if params[:page].present?
      @reservations = @reservations.page(params[:page]).per(per_page)
      paginate @reservations, per_page: per_page
    end
  end

  private
    def format_type(type)
      type.singularize.classify
    end

    def per_page
      params[:per_page] || 20
    end
end
