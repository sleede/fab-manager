# frozen_string_literal: true

# API Controller for resources of PaymentSchedule
class API::PaymentSchedulesController < API::APIController
  before_action :authenticate_user!
  before_action :set_payment_schedule, only: %i[download cancel update]
  before_action :set_payment_schedule_item, only: %i[show_item cash_check confirm_transfer refresh_item pay_item]

  # retrieve all payment schedules for the current user, paginated
  def index
    @payment_schedules = PaymentSchedule.where(invoicing_profile_id: current_user.invoicing_profile.id)
                                        .includes(:invoicing_profile, :payment_schedule_items, :payment_schedule_objects)
                                        .joins(:invoicing_profile)
                                        .order('payment_schedules.created_at DESC')
                                        .page(params[:page])
                                        .per(params[:size])
  end

  # retrieve all payment schedules for all users. Filtering is supported
  def list
    authorize PaymentSchedule

    p = params.require(:query).permit(:reference, :customer, :date, :page, :size)

    render json: { error: 'page must be an integer' }, status: :unprocessable_entity and return unless p[:page].is_a? Integer
    render json: { error: 'size must be an integer' }, status: :unprocessable_entity and return unless p[:size].is_a? Integer

    @payment_schedules = PaymentScheduleService.list(
      p[:page],
      p[:size],
      reference: p[:reference], customer: p[:customer], date: p[:date]
    )
  end

  def download
    authorize @payment_schedule
    send_file Rails.root.join(@payment_schedule.file), type: 'application/pdf', disposition: 'attachment'
  end

  def cash_check
    authorize @payment_schedule_item.payment_schedule
    PaymentScheduleService.new.generate_invoice(@payment_schedule_item, payment_method: 'check')
    attrs = { state: 'paid', payment_method: 'check' }
    @payment_schedule_item.update(attrs)

    render json: attrs, status: :ok
  end

  def confirm_transfer
    authorize @payment_schedule_item.payment_schedule
    PaymentScheduleService.new.generate_invoice(@payment_schedule_item, payment_method: 'transfer')
    attrs = { state: 'paid', payment_method: 'transfer' }
    @payment_schedule_item.update(attrs)

    render json: attrs, status: :ok
  end

  def refresh_item
    authorize @payment_schedule_item.payment_schedule
    PaymentScheduleItemWorker.new.perform(@payment_schedule_item.id)

    render json: { state: 'refreshed' }, status: :ok
  end

  def pay_item
    authorize @payment_schedule_item.payment_schedule

    res = PaymentGatewayService.new.pay_payment_schedule_item(@payment_schedule_item)
    if res.error
      render json: res, status: :unprocessable_entity
    else
      render json: res, status: :ok
    end
  end

  def show_item
    authorize @payment_schedule_item.payment_schedule
    render json: @payment_schedule_item, status: :ok
  end

  def cancel
    authorize @payment_schedule

    canceled_at = PaymentScheduleService.cancel(@payment_schedule)
    render json: { canceled_at: canceled_at }, status: :ok
  end

  ## Only the update of the payment method is allowed
  def update
    authorize PaymentSchedule

    if PaymentScheduleService.new.update_payment_mean(@payment_schedule, update_params)
      render :show, status: :ok, location: @payment_schedule
    else
      render json: @payment_schedule.errors, status: :unprocessable_entity
    end
  end

  private

  def set_payment_schedule
    @payment_schedule = PaymentSchedule.find(params[:id])
  end

  def set_payment_schedule_item
    @payment_schedule_item = PaymentScheduleItem.find(params[:id])
  end

  def update_params
    params.require(:payment_schedule).permit(:payment_method)
  end
end
