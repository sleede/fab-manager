# frozen_string_literal: true

# API Controller for resources of type iCalendar
class API::ICalendarController < API::APIController
  before_action :authenticate_user!, except: %i[index events]
  before_action :set_i_cal, only: [:destroy]
  respond_to :json

  def index
    @i_cals = ICalendar.all
  end

  def create
    authorize ICalendar
    @i_cal = ICalendar.new(i_calendar_params)
    if @i_cal.save
      render :show, status: :created, location: @i_cal
    else
      render json: @i_cal.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize ICalendar
    @i_cal.destroy
    head :no_content
  end

  def events
    start_date = ActiveSupport::TimeZone[params[:timezone]]&.parse(params[:start])
    end_date = ActiveSupport::TimeZone[params[:timezone]]&.parse(params[:end])&.end_of_day

    @events = ICalendarEvent.where(i_calendar_id: params[:id])
                            .where('dtstart >= ? AND dtend <= ?', start_date, end_date)
                            .joins(:i_calendar)
  end

  def sync
    ICalendarImportWorker.perform_async([params[:id]])
    render json: { processing: [params[:id]] }, status: :created
  end

  private

  def set_i_cal
    @i_cal = ICalendar.find(params[:id])
  end

  def i_calendar_params
    params.require(:i_calendar).permit(:name, :url, :color, :text_color, :text_hidden)
  end
end
