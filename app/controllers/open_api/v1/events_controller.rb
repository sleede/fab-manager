class OpenAPI::V1::EventsController < OpenAPI::V1::BaseController
  extend OpenAPI::ApiDoc
  expose_doc
  
  def index
    
	if upcoming
      @events = Event.includes(:event_image, :event_files, :availability, :category)
				.where('availabilities.end_at >= ?', Time.now)
                .order('availabilities.start_at ASC').references(:availabilities)
    else
	  @events = Event.includes(:event_image, :event_files, :availability, :category).order(created_at: :desc)
    end

    if params[:id].present?
      @events = @events.where(id: params[:id])
	end	

    if params[:page].present?
      @events = @events.page(params[:page]).per(per_page)
      paginate @events, per_page: per_page
    end
  end

  private
    def per_page
      params[:per_page] || 20
    end
	def upcoming
	  params[:upcoming] || false
	end
end
