class API::CreditsController < API::ApiController
  before_action :authenticate_user!
  before_action :set_credit, only: [:show, :update, :destroy]

  def index
    authorize Credit
    if params
      @credits = Credit.includes(:creditable).where(params.permit(:creditable_type))
    else
      @credits = Credit.includes(:creditable).all
    end
  end

  def create
    authorize Credit
    @credit = Credit.new(credit_params)
    if @credit.save
      render :show, status: :created, location: @credit
    else
      render json: @credit.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize Credit
    if @credit.update(credit_params)
      render :show, status: :ok, location: @credit
    else
      render json: @credit.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize Credit
    @credit.destroy
    head :no_content
  end

  private
    def set_credit
      @credit = Credit.find(params[:id])
    end

    def credit_params
      params.require(:credit).permit!
    end
end
