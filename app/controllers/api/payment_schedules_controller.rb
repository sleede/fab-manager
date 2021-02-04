# frozen_string_literal: true

# API Controller for resources of PaymentSchedule
class API::PaymentSchedulesController < API::ApiController
  before_action :authenticate_user!
  before_action :set_payment_schedule, only: %i[download]
  before_action :set_payment_schedule_item, only: %i[cash_check]

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
    send_file File.join(Rails.root, @payment_schedule.file), type: 'application/pdf', disposition: 'attachment'
  end

  def cash_check
    schedule = @payment_schedule_item.payment_schedule
    authorize schedule
    PaymentScheduleService.new.generate_invoice(@payment_schedule_item)
    @payment_schedule_item.update_attributes(state: 'paid', payment_method: 'check')

    render :show, status: :ok, location: schedule
  end

  private

  def set_payment_schedule
    @payment_schedule = PaymentSchedule.find(params[:id])
  end

  def set_payment_schedule_item
    @payment_schedule_item = PaymentScheduleItem.find(params[:id])
  end
end
