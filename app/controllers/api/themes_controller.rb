class API::ThemesController < API::ApiController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_theme, only: [:show, :update, :destroy]

  def index
    @themes = Theme.all
  end

  def show
  end

  def create
    authorize Theme
    @theme = Theme.new(theme_params)
    if @theme.save
      render :show, status: :created, location: @theme
    else
      render json: @theme.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize Theme
    if @theme.update(theme_params)
      render :show, status: :ok, location: @theme
    else
      render json: @theme.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize Theme
    @theme.destroy
    head :no_content
  end

  private
    def set_theme
      @theme = Theme.find(params[:id])
    end

    def theme_params
      params.require(:theme).permit(:name)
    end
end
