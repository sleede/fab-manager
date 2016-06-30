class API::CategoriesController < API::ApiController
  before_action :authenticate_user!, except: [:index]
  before_action :set_category, only: [:show, :update, :destroy]

  def index
    @categories = Category.all
  end

  def show
  end

  def create
    authorize Category
    @category = Category.new(category_params)
    if @category.save
      render :show, status: :created, location: @category
    else
      render json: @category.errors, status: :unprocessable_entity
    end
  end


  def update
    authorize Category
    if @category.update(category_params)
      render :show, status: :ok, location: @category
    else
      render json: @category.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize Category
    if @category.safe_destroy
      head :no_content
    else
      render json: @category.errors, status: :unprocessable_entity
    end
  end

  private
    def set_category
      @category = Category.find(params[:id])
    end

    def category_params
      params.require(:category).permit(:name)
    end
end
