class API::LicencesController < API::ApiController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_licence, only: [:show, :update, :destroy]

  def index
    @licences = Licence.all
  end

  def show
  end

  def create
    authorize Licence
    @licence = Licence.new(licence_params)
    if @licence.save
      render :show, status: :created, location: @licence
    else
      render json: @licence.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize Licence
    if @licence.update(licence_params)
      render :show, status: :ok, location: @licence
    else
      render json: @licence.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize Licence
    @licence.destroy
    head :no_content
  end

  private
    def set_licence
      @licence = Licence.find(params[:id])
    end

    def licence_params
      params.require(:licence).permit(:name, :description)
    end
end
