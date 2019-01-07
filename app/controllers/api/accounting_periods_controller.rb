class API::AccountingPeriodsController < API::ApiController

  before_action :authenticate_user!, except: %i[index show]
  before_action :set_period, only: %i[show update destroy]

  def index
    @accounting_periods = AccountingPeriod.all
  end

  def show; end

  def create
    authorize AccountingPeriod
    @accounting_period = AccountingPeriod.new(tag_params)
    if @accounting_period.save
      render :show, status: :created, location: @accounting_period
    else
      render json: @accounting_period.errors, status: :unprocessable_entity
    end
  end

  private

  def set_period
    @tag = AccountingPeriod.find(params[:id])
  end

  def period_params
    params.require(:accounting_period).permit(:start_date, :end_date)
  end
end
