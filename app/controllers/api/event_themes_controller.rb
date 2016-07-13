class API::EventThemesController < API::ApiController
  before_action :authenticate_user!, except: [:index]
  before_action :set_event_theme, only: [:show, :update, :destroy]

  def index
    @event_themes = EventTheme.all
  end

  def show
  end

  def create
    authorize EventTheme
    @event_theme = EventTheme.new(event_theme_params)
    if @event_theme.save
      render :show, status: :created, location: @event_theme
    else
      render json: @event_theme.errors, status: :unprocessable_entity
    end
  end


  def update
    authorize EventTheme
    if @event_theme.update(event_theme_params)
      render :show, status: :ok, location: @event_theme
    else
      render json: @event_theme.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize EventTheme
    if @event_theme.safe_destroy
      head :no_content
    else
      render json: @event_theme.errors, status: :unprocessable_entity
    end
  end

  private
  def set_event_theme
    @event_theme = EventTheme.find(params[:id])
  end

  def event_theme_params
    params.require(:event_theme).permit(:name)
  end
end
