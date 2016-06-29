class API::AgeRangesController < API::ApiController
  before_action :authenticate_user!, except: [:index]
  before_action :set_age_range, only: [:show, :update, :destroy]

  def index
    @age_ranges = AgeRange.all
  end

  def show
  end

  def create
    authorize AgeRange
    @age_range = AgeRange.new(age_range_params)
    if @age_range.save
      render :show, status: :created, location: @age_range
    else
      render json: @age_range.errors, status: :unprocessable_entity
    end
  end


  def update
    authorize AgeRange
    if @age_range.update(age_range_params)
      render :show, status: :ok, location: @age_range
    else
      render json: @age_range.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize AgeRange
    @age_range.destroy
    head :no_content
  end

  private
  def set_age_range
    @age_range = AgeRange.find(params[:id])
  end

  def age_range_params
    params.require(:age_range).permit(:name)
  end
end
