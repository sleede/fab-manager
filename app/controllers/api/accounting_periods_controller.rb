# frozen_string_literal: true

# API Controller for resources of AccountingPeriod
class API::AccountingPeriodsController < API::APIController
  before_action :authenticate_user!
  before_action :set_period, only: %i[show download_archive]

  def index
    @accounting_periods = Accounting::AccountingPeriodService.all_periods_with_users
  end

  def show; end

  def create
    authorize AccountingPeriod
    @accounting_period = AccountingPeriod.new(period_params.merge(closed_at: Time.current, closed_by: current_user.id))
    if @accounting_period.save
      render :show, status: :created, location: @accounting_period
    else
      render json: @accounting_period.errors, status: :unprocessable_entity
    end
  end

  def last_closing_end
    authorize AccountingPeriod
    last_period = Accounting::AccountingPeriodService.find_last_period
    if last_period.nil?
      invoice = Invoice.order(:created_at).first
      @last_end = invoice.created_at if invoice
    else
      @last_end = last_period.end_at + 1.day
    end
  end

  def download_archive
    authorize AccountingPeriod
    send_file Rails.root.join(@accounting_period.archive_file), type: 'application/json', disposition: 'attachment'
  end

  private

  def set_period
    @accounting_period = AccountingPeriod.find(params[:id])
  end

  def period_params
    params.require(:accounting_period).permit(:start_at, :end_at)
  end
end
