# frozen_string_literal: true

# API Controller for resources of type ReservationContext
class API::ReservationContextsController < API::APIController
  before_action :authenticate_user!, except: [:index]
  before_action :set_reservation_context, only: %i[show update destroy]

  def index
    @reservation_contexts = ReservationContext.all
    @reservation_contexts = @reservation_contexts.applicable_on(params[:applicable_on]) if params[:applicable_on].present?
    @reservation_contexts = @reservation_contexts.order(:created_at)
  end

  def show; end

  def create
    authorize ReservationContext
    @reservation_context = ReservationContext.new(reservation_context_params)
    if @reservation_context.save
      render :show, status: :created, location: @reservation_context
    else
      render json: @reservation_context.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize ReservationContext
    if @reservation_context.update(reservation_context_params)
      render :show, status: :ok, location: @reservation_context
    else
      render json: @reservation_context.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize ReservationContext
    if @reservation_context.safe_destroy
      head :no_content
    else
      render json: @reservation_context.errors, status: :unprocessable_entity
    end
  end

  def applicable_on_values
    authorize ReservationContext
    render json: ReservationContext::APPLICABLE_ON, status: :ok
  end

  private

  def set_reservation_context
    @reservation_context = ReservationContext.find(params[:id])
  end

  def reservation_context_params
    params.require(:reservation_context).permit(:name, applicable_on: [])
  end
end
