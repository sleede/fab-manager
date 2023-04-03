# frozen_string_literal: true

# API Controller for resources of type Coupon
# Coupons are used in payments
class API::CouponsController < API::APIController
  include ApplicationHelper

  before_action :authenticate_user!, except: %i[validate]
  before_action :set_coupon, only: %i[show update destroy]

  # Number of notifications added to the page when the user clicks on 'load next notifications'
  COUPONS_PER_PAGE = 10

  def index
    @coupons = Coupon.method(params[:filter]).call.page(params[:page]).per(COUPONS_PER_PAGE).order('created_at DESC')
    @total = Coupon.method(params[:filter]).call.length
  end

  def show; end

  def create
    authorize Coupon
    @coupon = Coupon.new(coupon_params)
    if @coupon.save
      render :show, status: :created, location: @coupon
    else
      render json: @coupon.errors, status: :unprocessable_entity
    end
  end

  def validate
    @coupon = Coupon.find_by(code: params[:code])
    if @coupon.nil?
      render json: { status: 'rejected' }, status: :not_found
    else
      user_id = if current_user&.admin?
                  params[:user_id]
                else
                  current_user&.id
                end

      status = @coupon.status(user_id, to_centimes(params[:amount]))
      if status == 'active'
        render :validate, status: :ok, location: @coupon
      else
        render json: { status: status }, status: :unprocessable_entity
      end
    end
  end

  def update
    authorize Coupon
    if @coupon.update(coupon_editable_params)
      render :show, status: :ok, location: @coupon
    else
      render json: @coupon.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize Coupon
    if @coupon.safe_destroy
      head :no_content
    else
      head :unprocessable_entity
    end
  end

  def send_to
    authorize Coupon

    @coupon = Coupon.find_by(code: params[:coupon_code])
    if @coupon.nil?
      render json: { error: "no coupon with code #{params[:coupon_code]}" }, status: :not_found
    elsif @coupon.send_to(params[:user_id])
      render :show, status: :ok, location: @coupon
    else
      render json: @coupon.errors, status: :unprocessable_entity
    end
  end

  private

  def set_coupon
    @coupon = Coupon.find(params[:id])
  end

  def coupon_params
    if @parameters
      @parameters
    else
      @parameters = params
      @parameters[:coupon][:amount_off] = to_centimes(@parameters[:coupon][:amount_off]) if @parameters[:coupon][:amount_off]

      @parameters = @parameters.require(:coupon).permit(:name, :code, :percent_off, :amount_off, :validity_per_user, :valid_until,
                                                        :max_usages, :active)
    end
  end

  def coupon_editable_params
    params.require(:coupon).permit(:name, :active, :valid_until)
  end
end
