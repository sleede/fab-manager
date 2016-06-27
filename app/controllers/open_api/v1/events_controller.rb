class OpenAPI::V1::EventsController < OpenAPI::V1::BaseController
  extend OpenAPI::ApiDoc
  expose_doc
  
  def index
    @events = Event.order(created_at: :desc)

    if params[:page].present?
      @events = @events.page(params[:page]).per(per_page)
      paginate @events, per_page: per_page
    end
  end

  private
    def per_page
      params[:per_page] || 20
    end
end
