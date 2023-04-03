# frozen_string_literal: true

# authorized 3rd party softwares can manage the events through the OpenAPI
class OpenAPI::V1::EventsController < OpenAPI::V1::BaseController
  extend OpenAPI::APIDoc
  include Rails::Pagination
  expose_doc

  def index
    @events = Event.includes(:event_image, :event_files, :availability, :category)
                   .where(deleted_at: nil)
    @events = if upcoming
                @events.references(:availabilities)
                       .where('availabilities.end_at >= ?', Time.current)
                       .order('availabilities.start_at ASC')
              else
                @events.order(created_at: :desc)
              end

    @events = @events.where(id: may_array(params[:id])) if params[:id].present?

    @events = @events.page(page).per(per_page)
    paginate @events, per_page: per_page
  end

  private

  def page
    params[:page] || 1
  end

  def per_page
    params[:per_page] || 20
  end

  def upcoming
    params[:upcoming] || false
  end
end
