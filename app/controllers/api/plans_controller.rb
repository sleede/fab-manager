# frozen_string_literal: true

# API Controller for resources of type Plan and PartnerPlan.
# Plan are used to define subscription's characteristics.
# PartnerPlan is a special kind of plan which send notifications to an external user
class API::PlansController < API::APIController
  include ApplicationHelper

  before_action :authenticate_user!, except: %i[index durations]

  def index
    @plans = Plan.includes(:plan_file)
    @plans = @plans.where(group_id: params[:group_id]) if params[:group_id]
    render :index
  end

  def show
    @plan = Plan.find(params[:id])
  end

  def create
    authorize Plan

    unless %w[PartnerPlan Plan].include? plan_params[:type]
      render json: { error: 'unhandled plan type' }, status: :unprocessable_entity and return
    end

    type = plan_params[:type]
    partner = params[:plan][:partner_id].blank? ? nil : User.find(params[:plan][:partner_id])

    plan = PlansService.create(type, partner, plan_params)
    if plan.key?(:errors)
      render json: plan.errors, status: :unprocessable_entity
    else
      render json: plan, status: :created
    end
  end

  def update
    @plan = Plan.find(params[:id])
    authorize @plan
    if @plan.update(plan_params)
      render :show, status: :ok
    else
      render json: @plan.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @plan = Plan.find(params[:id])
    authorize @plan
    @plan.destroy
    head :no_content
  end

  def durations
    grouped = Plan.all.map { |p| [p.human_readable_duration, p.id] }.group_by { |i| i[0] }
    @durations = []
    grouped.each_pair do |duration, plans|
      @durations.push(
        name: duration,
        plans: plans.map { |p| p[1] }
      )
    end
  end

  private

  def plan_params
    # parameters caching for performance
    if @parameters
      @parameters
    else
      @parameters = params
      @parameters[:plan][:amount] = to_centimes(@parameters[:plan][:amount]) if @parameters[:plan][:amount]
      if @parameters[:plan][:prices_attributes]
        @parameters[:plan][:prices_attributes] = @parameters[:plan][:prices_attributes].map do |price|
          { amount: to_centimes(price[:amount]), id: price[:id] }
        end
      end

      @parameters = @parameters.require(:plan)
                               .permit(:base_name, :type, :group_id, :amount, :interval, :interval_count, :is_rolling, :limiting,
                                       :training_credit_nb, :ui_weight, :disabled, :monthly_payment, :description, :plan_category_id,
                                       :machines_visibility,
                                       plan_file_attributes: %i[id attachment _destroy],
                                       prices_attributes: %i[id amount],
                                       advanced_accounting_attributes: %i[code analytical_section],
                                       plan_limitations_attributes: %i[id limitable_id limitable_type limit _destroy])
    end
  end
end
