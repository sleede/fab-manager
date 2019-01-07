# frozen_string_literal: true

# API Controller for resources of AccountingPeriod
class API::AccountingPeriodsController < API::ApiController

  before_action :authenticate_user!
  before_action :set_period, only: %i[show]

  def index
    @accounting_periods = AccountingPeriod.all
  end

  def show; end

  def create
    authorize AccountingPeriod
    @accounting_period = AccountingPeriod.new(period_params)
    if @accounting_period.save
      render :show, status: :created, location: @accounting_period
    else
      render json: @accounting_period.errors, status: :unprocessable_entity
    end
  end

  def last_closing_end
    authorize AccountingPeriod
    @last_period = AccountingPeriodService.find_last_period
  end

  private

  def set_period
    @tag = AccountingPeriod.find(params[:id])
  end

  def period_params
    params.require(:accounting_period).permit(:start_at, :end_at)
  end
end
