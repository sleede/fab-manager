# frozen_string_literal: true

# API Controller for resources of type Event
class API::EventsController < API::APIController
  before_action :set_event, only: %i[show update destroy]

  def index
    @events = policy_scope(Event)
    @page = params[:page]
    @scope = params[:scope]

    # filters
    @events = @events.joins(:category).where(categories: { id: params[:category_id] }) if params[:category_id]
    @events = @events.joins(:event_themes).where(event_themes: { id: params[:theme_id] }) if params[:theme_id]
    @events = @events.where(age_range_id: params[:age_range_id]) if params[:age_range_id]

    if current_user&.admin? || current_user&.manager?
      @events = case params[:scope]
                when 'future'
                  @events.where('availabilities.start_at >= ?', Time.current).order('availabilities.start_at DESC')
                when 'future_asc'
                  @events.where('availabilities.start_at >= ?', Time.current).order('availabilities.start_at ASC')
                when 'passed'
                  @events.where('availabilities.start_at < ?', Time.current).order('availabilities.start_at DESC')
                else
                  @events.order('availabilities.start_at DESC')
                end
    end

    # paginate
    @events = @events.page(@page).per(12)
  end

  # GET /events/upcoming/:limit
  def upcoming
    limit = params[:limit]
    @events = Event.includes(:event_image, :event_files, :availability, :category)
                   .where('events.nb_total_places != -1 OR events.nb_total_places IS NULL')
                   .where(deleted_at: nil)
                   .order('availabilities.start_at').references(:availabilities)
                   .limit(limit)

    @events = case Setting.get('upcoming_events_shown')
              when 'until_start'
                @events.where('availabilities.start_at >= ?', Time.current)
              when '2h_before_end'
                @events.where('availabilities.end_at >= ?', 2.hours.from_now)
              else
                @events.where('availabilities.end_at >= ?', Time.current)
              end
  end

  def show
    head :not_found if @event.deleted_at
  end

  def create
    authorize Event
    @event = Event.new(event_params.permit!)
    if @event.save
      service = Availabilities::CreateAvailabilitiesService.new
      service.create_slots(@event.availability)
      render :show, status: :created, location: @event
    else
      render json: @event.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize Event
    res = Event::UpdateEventService.update(@event, event_params.permit!, params[:edit_mode])
    render json: { action: 'update', total: res[:events].length, updated: res[:events].select { |r| r[:status] }.length, details: res },
           status: :ok,
           location: @event
  end

  def destroy
    authorize Event
    res = EventService.delete(params[:id], params[:mode])
    if res.all? { |r| r[:status] }
      render json: { deleted: res.length, details: res }, status: :ok
    else
      render json: { total: res.length, deleted: res.select { |r| r[:status] }.length, details: res }, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_event
    @event = Event.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def event_params
    # handle general properties
    event_preparams = params.required(:event).permit(:title, :description, :start_date, :start_time, :end_date, :end_time,
                                                     :amount, :nb_total_places, :availability_id, :all_day, :recurrence,
                                                     :recurrence_end_at, :category_id, :event_theme_ids, :age_range_id, :booking_nominative,
                                                     event_theme_ids: [],
                                                     event_image_attributes: %i[id attachment],
                                                     event_files_attributes: %i[id attachment _destroy],
                                                     event_price_categories_attributes: %i[id price_category_id amount _destroy],
                                                     advanced_accounting_attributes: %i[code analytical_section])
    EventService.process_params(event_preparams)
  end
end
