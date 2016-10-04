class API::PriceCategoriesController < API::ApiController
  before_action :authenticate_user!, only: [:update, :show, :create, :destroy]
  before_action :set_price_category, only: [:show, :update, :destroy]

  def index
    @price_categories = PriceCategory.all
  end

  def update
    authorize PriceCategory
    if @price_category.update(price_category_params)
      render :show, status: :ok, location: @price_category
    else
      render json: @price_category.errors, status: :unprocessable_entity
    end
  end

  def show
  end

  def create
    authorize PriceCategory
    @price_category = PriceCategory.new(price_category_params)
    if @price_category.save
      render :show, status: :created, location: @price_category
    else
      render json: @price_category.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize PriceCategory
    if @price_category.safe_destroy
      head :no_content
    else
      render json: @price_category.errors, status: :unprocessable_entity
    end
  end

  private
  def set_price_category
    @price_category = PriceCategory.find(params[:id])
  end

  def price_category_params
    params.require(:price_category).permit(:name, :conditions)
  end
end