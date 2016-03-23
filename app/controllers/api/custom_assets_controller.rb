class API::CustomAssetsController < API::ApiController
  before_action :authenticate_user!, only: [:index, :update, :create, :destroy]
  before_action :set_custom_asset, only: [:show, :update, :destroy]

  def index
    #TODO GET /api/custom_assets/
  end

  # PUT /api/custom_assets/1/
  def update
    authorize CustomAsset
    if @custom_asset.update(custom_asset_params.permit!)
      render :show, status: :ok, location: @custom_asset
    else
      render json: @custom_asset.errors, status: :unprocessable_entity
    end
  end

  # POST /api/custom_assets/
  def create
    authorize CustomAsset
    @custom_asset = CustomAsset.new(custom_asset_params.permit!)
    if @custom_asset.save
      render :show, status: :created, location: @custom_asset
    else
      render json: @custom_asset.errors, status: :unprocessable_entity
    end
  end

  # GET /api/custom_assets/1/
  def show
  end

  def destroy
    #TODO DELETE /api/custom_assets/1/
  end

  private
  def set_custom_asset
    @custom_asset = CustomAsset.find_by(name: params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def custom_asset_params
    params.required(:custom_asset).permit(:name, custom_asset_file_attributes: [:attachment])
  end

end