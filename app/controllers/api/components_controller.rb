class API::ComponentsController < API::ApiController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_component, only: [:show, :update, :destroy]

  def index
    @components = Component.all
  end

  def show
  end

  def create
    authorize Component
    @component = Component.new(component_params)
    if @component.save
      render :show, status: :created, location: @component
    else
      render json: @component.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize Component
    if @component.update(component_params)
      render :show, status: :ok, location: @component
    else
      render json: @component.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize Component
    @component.destroy
    head :no_content
  end

  private
    def set_component
      @component = Component.find(params[:id])
    end

    def component_params
      params.require(:component).permit(:name)
    end
end
