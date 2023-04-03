# frozen_string_literal: true

# @deprecated
# <b>DEPRECATED:</b> Please use <tt>API::PriceController</tt> instead.
# API Controller for managing Plans prices
class API::PricingController < API::APIController
  include ApplicationHelper

  before_action :authenticate_user!, except: %i[index update]

  def index
    @group_pricing = Group.includes(:plans, :trainings_pricings)
  end

  def update
    authorize :pricing, :update?
    if params[:training].present?
      training = Training.find params[:training]
      params[:group_pricing].each do |group_id, amount|
        next unless training

        group = Group.includes(:plans).find(group_id)
        next unless group

        training_pricing = group.trainings_pricings.find_or_initialize_by(training_id: training.id)
        training_pricing.amount = to_centimes(amount)
        training_pricing.save
      end
    end
    head :ok
  end
end
