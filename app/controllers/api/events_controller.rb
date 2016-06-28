class API::EventsController < API::ApiController
  before_action :set_event, only: [:show, :edit, :update, :destroy]

  def index
    @events = policy_scope(Event)
    @total = @events.count
    @page = params[:page]
    @events = @events.page(@page).per(12)
  end

  # GET /events/upcoming/:limit
  def upcoming
    limit = params[:limit]
    @events = Event.includes(:event_image, :event_files, :availability, :categories)
                   .where('availabilities.start_at >= ?', Time.now)
                   .order('availabilities.start_at ASC').references(:availabilities).limit(limit)
  end

  def show
  end

  def create
    authorize Event
    @event = Event.new(event_params.permit!)
    if @event.save
      render :show, status: :created, location: @event
    else
      render json: @event.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize Event
    if @event.update(event_params.permit!)
      render :show, status: :ok, location: @event
    else
      render json: @event.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize Event
    if @event.safe_destroy
      head :no_content
    else
      head :unprocessable_entity
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def event_params
      event_preparams = params.required(:event).permit(:title, :description, :start_date, :start_time, :end_date, :end_time,
                                                    :amount, :reduced_amount, :nb_total_places, :availability_id,
                                                    :all_day, :recurrence, :recurrence_end_at, :category_ids, category_ids: [],
                                                    event_image_attributes: [:attachment], event_files_attributes: [:id, :attachment, :_destroy])
      start_date = Time.zone.parse(event_preparams[:start_date])
      end_date = Time.zone.parse(event_preparams[:end_date])
      start_time = Time.parse(event_preparams[:start_time]) if event_preparams[:start_time]
      end_time = Time.parse(event_preparams[:end_time]) if event_preparams[:end_time]
      if event_preparams[:all_day] == 'true'
        start_at = DateTime.new(start_date.year, start_date.month, start_date.day, 0, 0, 0, start_date.zone)
        end_at = DateTime.new(end_date.year, end_date.month, end_date.day, 23, 59, 59, end_date.zone)
      else
        start_at = DateTime.new(start_date.year, start_date.month, start_date.day, start_time.hour, start_time.min, start_time.sec, start_date.zone)
        end_at = DateTime.new(end_date.year, end_date.month, end_date.day, end_time.hour, end_time.min, end_time.sec, end_date.zone)
      end
      event_preparams.merge!(availability_attributes: {id: event_preparams[:availability_id], start_at: start_at, end_at: end_at, available_type: 'event'})
                     .except!(:start_date, :end_date, :start_time, :end_time, :all_day)
      event_preparams.merge!(amount: (event_preparams[:amount].to_i * 100 if event_preparams[:amount].present?),
                             reduced_amount: (event_preparams[:reduced_amount].to_i * 100 if event_preparams[:reduced_amount].present?))
    end


end
